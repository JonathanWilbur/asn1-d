/*
    Just a field test for initiating a connection to a remote LDAP server.

    Build with:
    dmd -I./output/interfaces/source -L./output/libraries/asn1-<version>.a ./test/handshake.d -of./output/executables/handshake -d
*/
import std.socket : InternetAddress, TcpSocket;
import std.stdio : writefln, writeln;
import asn1.constants;
import asn1.codecs.ber : BERElement;

void main()
{
    /*
        The BindRequest should look like this:

        LDAPMessage ::= SEQUENCE {
            messageID       INTEGER (0 .. 2147483647),
            protocolOp      CHOICE {
                [APPLICATION 0] SEQUENCE {
                    version                 INTEGER (1 .. 127),
                    name                    OCTET STRING,
                    authentication          CHOICE {
                        simple                  [0] OCTET STRING } } } }

        Example from https://cwiki.apache.org/confluence/display/DIRxASN1/BindRequest:

            0x30 0x33
                0x02 0x01 0x01
                0x60 0x2E
                    0x02 0x01 0x03
                    0x04 0x1F 0x75 0x69 0x64 0x3D 0x61 0x6B 0x61 0x72 0x61 0x73 0x75 0x6C 0x75 0x2C 0x64 0x63
                            0x3D 0x65 0x78 0x61 0x6D 0x70 0x6C 0x65 0x2C 0x64 0x63 0x3D 0x63 0x6F 0x6D
                    0x80 0x08 0x70 0x61 0x73 0x73 0x77 0x6F 0x72 0x64
    */
    ubyte[] bindBytes = [];
    {
        BERElement messageRoot = new BERElement();
        BERElement messageMessageID = new BERElement();
        BERElement messageProtocolOp = new BERElement();
        BERElement messageBindRequestVersion = new BERElement();
        BERElement messageBindRequestName = new BERElement();
        BERElement messageBindRequentAuthenticationSimple = new BERElement();

        // version
        messageBindRequestVersion.tagNumber = ASN1UniversalType.integer;
        messageBindRequestVersion.integer!int = 3;

        // name
        messageBindRequestName.tagNumber = ASN1UniversalType.octetString;
        messageBindRequestName.octetString = cast(ubyte[]) "cn=read-only-admin,dc=example,dc=com";

        // authentication (simple)
        messageBindRequentAuthenticationSimple.tagClass = ASN1TagClass.contextSpecific;
        messageBindRequentAuthenticationSimple.tagNumber = 0u;
        messageBindRequentAuthenticationSimple.octetString = cast(ubyte[]) "password";

        // messageID
        messageMessageID.tagNumber = ASN1UniversalType.integer;
        messageMessageID.integer!int = 1;

        // protocolOp
        messageProtocolOp.tagClass = ASN1TagClass.application;
        messageProtocolOp.construction = ASN1Construction.constructed;
        messageProtocolOp.tagNumber = 0u;
        messageProtocolOp.sequence = [
            messageBindRequestVersion,
            messageBindRequestName,
            messageBindRequentAuthenticationSimple
        ];

        messageRoot.construction = ASN1Construction.constructed;
        messageRoot.tagNumber = ASN1UniversalType.sequence;
        messageRoot.sequence = [ messageMessageID, messageProtocolOp ];

        bindBytes = messageRoot.toBytes;
    }

    TcpSocket socket = new TcpSocket(new InternetAddress("ldap.forumsys.com", 389u));
    scope(exit) socket.close();

    writefln("BindRequest: %(%02X %)", bindBytes);
    socket.send(bindBytes);
    writeln();

    /*
        The response should look like this:

        LDAPMessage ::= SEQUENCE {
            messageID       INTEGER (0 .. 2147483647),
            protocolOp      CHOICE {
                [APPLICATION 1] SEQUENCE {
                    resultCode         ENUMERATED (0), -- If successful
                    matchedDN          OCTET STRING,
                    diagnosticMessage  OCTET STRING,
                    serverSaslCreds    [7] OCTET STRING OPTIONAL } },
            controls       [0] Controls OPTIONAL }
    */
    BERElement response = new BERElement();
    ubyte[] responseBytes;
    ubyte[1] responseBuffer;
    size_t exceptionCounter = 0u;
    while (socket.receive(responseBuffer) && exceptionCounter < 100u)
    {
        size_t reffy = 0u;
        responseBytes ~= responseBuffer.dup;
        try
        {
            BERElement root = new BERElement(reffy, responseBytes);
            response = root;
            if (reffy == responseBytes.length) break;
        }
        catch (ASN1Exception e)
        {
            exceptionCounter++;
        }
    }

    writefln("Response Bytes: %(%02X %)", response.toBytes);

    if (exceptionCounter == 100u)
    {
        writeln("Too many exceptions. Quitting.");
        return;
    }

    // Verification of the root SEQUENCE
    {
        if (response.tagClass != ASN1TagClass.universal)
        {
            writeln("Response was not APPLICATION.");
            return;
        }

        if (response.construction != ASN1Construction.constructed)
        {
            writeln("Response was not constructed.");
            return;
        }

        if (response.tagNumber != ASN1UniversalType.sequence)
        {
            writeln("Response did not have a tag number of 1.");
            return;
        }
    }

    BERElement[] components = response.sequence;

    // Verification of the SEQUENCE elements
    {
        if (components.length < 2u || components.length > 3u)
        {
            writeln("Response SEQUENCE did not contain 2 or 3 components.");
            return;
        }
    }

    // Verification of the messageID
    {
        if (components[0].tagClass != ASN1TagClass.universal)
        {
            writeln("Tag class of messageID was not UNIVERSAL.");
            return;
        }

        if (components[0].construction != ASN1Construction.primitive)
        {
            writeln("Construction of messageID was not primitive.");
            return;
        }

        if (components[0].tagNumber != ASN1UniversalType.integer)
        {
            writeln("MessageID did not have the right tag number.");
            return;
        }
    }
    writeln("BindResponse message ID: ", components[0].integer!int);

    // Verification of the protocolOp
    {
        if (components[1].tagClass != ASN1TagClass.application)
        {
            writeln("Tag class of protocolOp was not APPLICATION.");
            return;
        }

        if (components[1].construction != ASN1Construction.constructed)
        {
            writeln("Construction of protocolOp was not constructed.");
            return;
        }

        if (components[1].tagNumber != 1u)
        {
            writeln("ProtocolOp did not have the right tag number.");
            return;
        }
    }

    BERElement[] protocolOp = components[1].sequence;

    if (protocolOp.length != 3u)
    {
        writeln("ProtocolOp was not three elements long.");
        return;
    }

    foreach (component; protocolOp)
    {
        if (component.tagClass != ASN1TagClass.universal)
        {
            writeln("ProtocolOp contained a non-primitive element");
            return;
        }

        if (component.construction != ASN1Construction.primitive)
        {
            writeln("ProtocolOp contained a non-primitive element");
            return;
        }
    }

    // Verification of the resultCode
    {
        if (protocolOp[0].tagNumber != ASN1UniversalType.enumerated)
        {
            writeln("ProtocolOp did not have the right tag number.");
            return;
        }

        if (protocolOp[1].tagNumber != ASN1UniversalType.octetString)
        {
            writeln("ProtocolOp did not have the right tag number.");
            return;
        }

        if (protocolOp[2].tagNumber != ASN1UniversalType.octetString)
        {
            writeln("ProtocolOp did not have the right tag number.");
            return;
        }
    }

    writeln("Result Code: ", protocolOp[0].integer!int);
    writeln("Matched DN: ", cast(string) protocolOp[1].octetString);
    writeln("Diagnostic Message: ", cast(string) protocolOp[2].octetString);

    /*
        And the unbind request should look like this:

        LDAPMessage ::= SEQUENCE {
            messageID       INTEGER (0 .. 2147483647),
            protocolOp      CHOICE {
                UnbindRequest ::= [APPLICATION 2] NULL } }
    */
    ubyte[] unbindBytes = [];
    {
        BERElement messageRoot = new BERElement();
        BERElement messageMessageID = new BERElement();
        BERElement messageProtocolOp = new BERElement();

        // messageID
        messageMessageID.tagNumber = ASN1UniversalType.integer;
        messageMessageID.integer!int = 3;

        // protocolOp
        messageProtocolOp.tagClass = ASN1TagClass.application;
        messageProtocolOp.tagNumber = 2u;

        messageRoot.construction = ASN1Construction.constructed;
        messageRoot.tagNumber = ASN1UniversalType.sequence;
        messageRoot.sequence = [ messageMessageID, messageProtocolOp ];

        unbindBytes = messageRoot.toBytes;
    }

    socket.send(unbindBytes);
}