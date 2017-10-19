/**
    Basic Encoding Rules (BER) is a standard for encoding ASN.1 data. It is by
    far the most common standard for doing so, being used in LDAP, TLS, SNMP, 
    RDP, and other protocols. Like Distinguished Encoding Rules (DER), 
    Canonical Encoding Rules (CER), and Packed Encoding Rules (PER), Basic
    Encoding Rules is a specification created by the 
    $(LINK2 http://www.itu.int/en/pages/default.aspx, 
        International Telecommunications Union),
    and specified in 
    $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)
    
    BER is generally regarded as the most flexible of the encoding schemes, 
    because all values can be encoded in a multitude of ways. This flexibility
    might be convenient for developers who use a BER Library, but creating
    a BER library in the first place is a nightmare, because of its flexibility.
    I personally suspect that the complexity of BER may make its implementation
    inclined to security vulnerabilities, so I would not use it if you have a
    choice in the matter. Also, the ability to represent values in several 
    different ways is actually a security problem when data has to be guarded 
    against tampering with a cryptographic signature. (Basically, it makes it 
    a lot easier to find a tampered payload that has the identical signature 
    as the genuine payload.)

    Author: 
        $(LINK2 http://jonathan.wilbur.space, Jonathan M. Wilbur) 
            $(LINK2 mailto:jonathan@wilbur.space, jonathan@wilbur.space)
    License: $(https://opensource.org/licenses/ISC, ISC License)
    Standards:
        $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1))
        $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)
    See_Also:
        $(LINK2 https://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One, The Wikipedia Page on ASN.1)
        $(LINK2 https://en.wikipedia.org/wiki/X.690, The Wikipedia Page on X.690)
        $(LINK2 https://www.strozhevsky.com/free_docs/asn1_in_simple_words.pdf, ASN.1 By Simple Words)
        $(LINK2 http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF, ASN.1: Communication Between Heterogeneous Systems)
*/
module codecs.ber;
public import codec;
public import types.identification;

///
public alias BERValue = BasicEncodingRulesValue;
/**
    The unit of encoding and decoding for Basic Encoding Rules (BER).
    There are three parts to an encoded BER Value:

    $(UL
        $(LI A Type Tag, which specifies what data type is encoded)
        $(LI A Length Tag, which specifies how many subsequent bytes encode the data)
        $(LI The Encoded Value)
    )

    They appear in the binary encoding in that order, and as such, the encoding
    scheme is sometimes described as "TLV," which stands for Type-Length-Value.

    This class provides a properties for getting and setting bit fields of
    the type tag, but most of it is functionality for encoding data per
    the specification.

    As an example, this is what encoding a simple INTEGER looks like:

    ---
    BERValue bv = new BERValue();
    bv.type = 0x02u; // "2" means this is an INTEGER
    bv.integer = 1433; // Now the data is encoded.
    transmit(cast(ubyte[]) bv); // transmit() is a made-up function.
    ---

    And this is what decoding looks like:

    ---
    ubyte[] data = receive(); // receive() is a made-up function.
    BERValue bv2 = new BERValue(data);

    long x;
    if (bv.type == 0x02u) // it is an INTEGER
    {
        x = bv.integer;
    }
    // Now x is 1433!
    ---
*/
/* FIXME:
    This class should be "final," but a bug in the DMD compiler produces
    unlinkable objects if a final class inherits an alias to an internal
    member of a parent class.

    I have reported this to the D Language Foundation's Bugzilla site on
    17 October, 2017, and this bug can be viewed here:
    https://issues.dlang.org/show_bug.cgi?id=17909
*/
public
class BasicEncodingRulesValue : ASN1BinaryValue
{
    /*
        Returns true if the value octets contain two consecutive 0x00u bytes.

        The intent of this is to be used for indefinite-length encoding, which
        cannot contain two consecutive null octets as the value.
    */
    private @property
    bool valueContainsDoubleNull()
    {
        if (this.value.length < 2u) return false;
        for (size_t i = 1; i < this.value.length; i++)
        {
            if (this.value[i] == 0x00u && this.value[i-1] == 0x00u)
                return true;
        }
        return false;
    }

    /**
        Decodes a boolean.
        
        Any non-zero value will be interpreted as TRUE. Only zero will be
        interpreted as FALSE.
        
        Returns: a boolean
        Throws:
            ASN1ValueSizeException = if the encoded value is anything other
                than exactly 1 byte in size.
    */
    // FIXME: Throw exception if length is invalid.
    override public @property @safe
    bool boolean()
    {
        if (this.value.length != 1)
            throw new ASN1ValueSizeException
            ("An ASN.1 BOOLEAN must be exactly 1 byte in size.");

        return (this.value[0] ? true : false);
    }

    /**
        Encodes a boolean.

        Any non-zero value will be interpreted as TRUE. Only zero will be
        interpreted as FALSE.
    */
    override public @property @safe nothrow
    void boolean(bool value)
    {
        this.value = [(value ? 0xFFu : 0x00u)];
    }

    ///
    @safe
    unittest
    {
        BERValue bv = new BERValue();
        bv.boolean = true;
        assert(bv.boolean == true);
        bv.boolean = false;
        assert(bv.boolean == false);
        bv.value = [ 0x01u ];
        assert(bv.boolean == true);
        bv.value = [ 0xFFu ];
        assert(bv.boolean == true);
        bv.value = [ 0x00u ];
        assert(bv.boolean == false);
        bv.value = [ 0x01u, 0x00u ];
        assertThrown!ASN1ValueSizeException(bv.boolean);
        bv.value = [];
        assertThrown!ASN1ValueSizeException(bv.boolean);
    }

    /**
        Decodes a signed integer.
        
        Bytes are stored in big-endian order, where the bytes represent 
        the two's complement encoding of the integer.

        Returns: any chosen signed integral type
        Throws:
            ASN1ValueTooBigException = if the value is too big to decode
                to a signed integral type.
    */
    public @property @system
    T integer(T)()
    if (isIntegral!T && isSigned!T)
    {
        /* NOTE:
            this.value must be duplicated; if it is not, the reverse() operation
            below reverses this.value, which persists until the next decode!
        */
        ubyte[] value = this.value.dup;
        if (value.length > T.sizeof)
            throw new ASN1ValueTooBigException
            ("INTEGER is too big to be decoded.");

        /* NOTE:
            Because the BER INTEGER is stored in two's complement form, you 
            can't just apppend 0x00u to the big end of it until it is as long
            as T in bytes, then cast to T. Instead, you have to first determine
            if the encoded integer is negative or positive. If it is negative,
            then you actually want to append 0xFFu to the big end until it is
            as big as T, so you get the two's complement form of whatever T
            you choose.

            The line immediately below this determines whether the padding byte
            should be 0xFF or 0x00 based on the most significant bit of the 
            most significant byte (which, since BER encodes big-endian, will
            always be the first byte). If set (1), the number is negative, and
            hence, the padding byte should be 0xFF. If not, it is positive,
            and the padding byte should be 0x00.
        */
        ubyte paddingByte = ((this.value[0] & 0x80u) ? 0xFFu : 0x00u);
        while (value.length < T.sizeof)
            value = (paddingByte ~ value);

        version (LittleEndian)
        {
            reverse(value);
        }
        return *cast(T *) value.ptr;
    }

    /**
        Encodes an integer.
        
        Bytes are stored in big-endian order, where the bytes represent 
        the two's complement encoding of the integer.
    */
    public @property @system nothrow
    void integer(T)(T value)
    if (isIntegral!T && isSigned!T)
    {
        ubyte[] ub;
        ub.length = T.sizeof;
        *cast(T *)&ub[0] = value;
        version (LittleEndian)
        {
            reverse(ub);
        }
        this.value = ub[0 .. $];
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();

        // Tests for zero
        bv.integer!byte = 0;
        assert(bv.integer!byte == 0);
        assert(bv.integer!short == 0);
        assert(bv.integer!int == 0);
        assert(bv.integer!long == 0L);

        bv.integer!short = 0;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assert(bv.integer!short == 0);
        assert(bv.integer!int == 0);
        assert(bv.integer!long == 0L);

        bv.integer!int = 0;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assert(bv.integer!int == 0);
        assert(bv.integer!long == 0L);

        bv.integer!long = 0L;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assertThrown!ASN1ValueTooBigException(bv.integer!int);
        assert(bv.integer!long == 0L);

        // Tests for small positives
        bv.integer!byte = 3;
        assert(bv.integer!byte == 3);
        assert(bv.integer!short == 3);
        assert(bv.integer!int == 3);
        assert(bv.integer!long == 3L);

        bv.integer!short = 5;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assert(bv.integer!short == 5);
        assert(bv.integer!int == 5);
        assert(bv.integer!long == 5L);

        bv.integer!int = 7;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assert(bv.integer!int == 7);
        assert(bv.integer!long == 7L);

        bv.integer!long = 9L;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assertThrown!ASN1ValueTooBigException(bv.integer!int);
        assert(bv.integer!long == 9L);

        // Tests for small negatives
        bv.integer!byte = -3;
        assert(bv.integer!byte == -3);
        assert(bv.integer!short == -3);
        assert(bv.integer!int == -3);
        assert(bv.integer!long == -3L);

        bv.integer!short = -5;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assert(bv.integer!short == -5);
        assert(bv.integer!int == -5);
        assert(bv.integer!long == -5L);

        bv.integer!int = -7;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assert(bv.integer!int == -7);
        assert(bv.integer!long == -7L);

        bv.integer!long = -9L;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assertThrown!ASN1ValueTooBigException(bv.integer!int);
        assert(bv.integer!long == -9L);

        // Tests for large positives
        bv.integer!short = 20000;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assert(bv.integer!short == 20000);
        assert(bv.integer!int == 20000);
        assert(bv.integer!long == 20000L);

        bv.integer!int = 70000;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assert(bv.integer!int == 70000);
        assert(bv.integer!long == 70000L);

        bv.integer!long = 70000L;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assertThrown!ASN1ValueTooBigException(bv.integer!int);
        assert(bv.integer!long == 70000L);

        // Tests for large negatives
        bv.integer!short = -20000;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assert(bv.integer!short == -20000);
        assert(bv.integer!int == -20000);
        assert(bv.integer!long == -20000L);

        bv.integer!int = -70000;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assert(bv.integer!int == -70000);
        assert(bv.integer!long == -70000L);

        bv.integer!long = -70000L;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assertThrown!ASN1ValueTooBigException(bv.integer!int);
        assert(bv.integer!long == -70000L);

        // Tests for maximum values
        bv.integer!byte = byte.max;
        assert(bv.integer!byte == byte.max);
        assert(bv.integer!short == byte.max);
        assert(bv.integer!int == byte.max);
        assert(bv.integer!long == byte.max);

        bv.integer!short = short.max;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assert(bv.integer!short == short.max);
        assert(bv.integer!int == short.max);
        assert(bv.integer!long == short.max);

        bv.integer!int = int.max;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assert(bv.integer!int == int.max);
        assert(bv.integer!long == int.max);

        bv.integer!long = long.max;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assertThrown!ASN1ValueTooBigException(bv.integer!int);
        assert(bv.integer!long == long.max);

        // Tests for minimum values
        bv.integer!byte = byte.min;
        assert(bv.integer!byte == byte.min);
        assert(bv.integer!short == byte.min);
        assert(bv.integer!int == byte.min);
        assert(bv.integer!long == byte.min);

        bv.integer!short = short.min;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assert(bv.integer!short == short.min);
        assert(bv.integer!int == short.min);
        assert(bv.integer!long == short.min);

        bv.integer!int = int.min;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assert(bv.integer!int == int.min);
        assert(bv.integer!long == int.min);

        bv.integer!long = long.min;
        assertThrown!ASN1ValueTooBigException(bv.integer!byte);
        assertThrown!ASN1ValueTooBigException(bv.integer!short);
        assertThrown!ASN1ValueTooBigException(bv.integer!int);
        assert(bv.integer!long == long.min);
    }

    /**
        Decodes a BitArray. 
        
        The first byte is an unsigned number of the unused bits in the last 
        byte of the encoded bit array.

        Returns: a std.bitmanip.BitArray.
        Throws:
            ASN1InvalidValueException = if the first byte is greater than
                seven, which indicates more than seven unused bits on the
                last byte of the BIT STRING, which is obviously 
                impossible, since a byte has 8 bits.
    */
    // NOTE: This has to be @system because BitArray sucks.
    override public @property @system
    BitArray bitString()
    {
        if (this.value[0] > 0x07u)
            throw new ASN1InvalidValueException
            ("Unused bits byte cannot have a value greater than seven.");
        ubyte[] val = this.value[1 .. $];
        while (val.length % size_t.sizeof) val ~= 0x00u;
        return BitArray(val, cast(size_t) (((this.length - 1u) * 8u) - this.value[0]));
    }

    /**
        Encodes a BitArray. 
        
        The first byte is an unsigned number of the unused
        bits in the last byte of the encoded bit array.
    */
    // NOTE: This has to be @system because BitArray sucks.
    override public @property @system nothrow
    void bitString(BitArray value)
    {
        // REVIEW: is 0x08u - (value.length % 0x08u) == 0x08u % value.length?
        size_t bitsNeeded = value.length; // value.length is the length in bits, not bytes.
        while (bitsNeeded % 8u) bitsNeeded++; // round up to the nearest byte.
        size_t bytesNeeded = bitsNeeded / 8u;
        ubyte[] valueBytes = cast(ubyte[]) (cast(void[]) value);
        valueBytes.length = bytesNeeded;
        this.value = [ cast(ubyte) (0x08u - (value.length % 0x08u)) ] ~ valueBytes;
    }

    ///
    @system
    unittest
    {
        BitArray ba = BitArray([true, false, true, true, false]);
        BERValue bv = new BERValue();
        bv.bitString = ba;
        assert(bv.bitString == ba);
    }

    /**
        Decodes an OCTET STRING into an unsigned byte array.

        Returns: an unsigned byte array.
    */
    override public @property @safe
    ubyte[] octetString()
    {
        return this.value;
    }

    /**
        Encodes an OCTET STRING from an unsigned byte array.
    */
    override public @property @safe
    void octetString(ubyte[] value)
    {
        this.value = value;
    }

    ///
    @safe
    unittest
    {
        BERValue bv = new BERValue();
        bv.octetString = [ 0x05u, 0x02u, 0xFFu, 0x00u, 0x6Au ];
        assert(bv.octetString == [ 0x05u, 0x02u, 0xFFu, 0x00u, 0x6Au ]);
    }

    /**
        Decodes an OBJECT IDENTIFIER.
        See source/types/universal/objectidentifier.d for information about
        the ObjectIdentifier class (aliased as "OID").

        The encoded OBJECT IDENTIFIER's first byte contains the first number
        of the OID multiplied by 40 and added to the second number of the OID.
        The subsequent bytes have all the remaining number encoded in base-128
        on the least significant 7 bits of each byte. For these bytes, the most
        significant bit is set if the next byte continues the encoding of the
        current OID number. In other words, the bytes encoding each number
        always end with a byte whose most significant bit is cleared.

        Standards:
            $(LINK2 http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660)
    */
    // FIXME: change number sizes to size_t and add overflow checking.
    override public @property @safe
    OID objectIdentifier()
    {
        ulong[] oidComponents = [ (this.value[0] / 0x28u), (this.value[0] % 0x28u) ];

        // The loop below breaks the bytes into components.
        ubyte[][] components;
        ptrdiff_t lastTerminator = 1;
        for (int i = 1; i < this.length; i++)
        {
            if (!(this.value[i] & 0x80u))
            {
                components ~= this.value[lastTerminator .. i+1];
                lastTerminator = i+1;
            }
        }

        // The loop below converts each array of bytes (component) into a ulong, and appends it.
        foreach (component; components)
        {
            oidComponents ~= 0u;
            for (ptrdiff_t i = 0; i < component.length; i++)
            {
                oidComponents[$-1] <<= 7;
                oidComponents[$-1] |= cast(ulong) (component[i] & 0x7Fu);
            }
        }

        return new OID(oidComponents);
    }

    /**
        Encodes an OBJECT IDENTIFIER.
        See source/types/universal/objectidentifier.d for information about
        the ObjectIdentifier class (aliased as "OID").

        The encoded OBJECT IDENTIFIER's first byte contains the first number
        of the OID multiplied by 40 and added to the second number of the OID.
        The subsequent bytes have all the remaining number encoded in base-128
        on the least significant 7 bits of each byte. For these bytes, the most
        significant bit is set if the next byte continues the encoding of the
        current OID number. In other words, the bytes encoding each number
        always end with a byte whose most significant bit is cleared.

        Standards:
            $(LINK2 http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660)
    */
    // FIXME: change number sizes to size_t and add overflow checking.
    override public @property @safe
    void objectIdentifier(OID value)
    {
        ulong[] oidComponents = value.numericArray();
        if (oidComponents.length == 1) oidComponents ~= 0L; // So the next line does not fail.
        this.value = [ cast(ubyte) (oidComponents[0] * 40u + oidComponents[1]) ]; //FIXME: This might be suceptable to overflow attacks.
        if (oidComponents.length > 2)
        {
            foreach (x; oidComponents[2 .. $])
            {
                ubyte[] encodedOIDComponent;
                if (x == 0) // REVIEW: Could you make this faster by using if (x < 128)?
                {
                    this.value ~= 0x00u;
                    continue;
                }
                while (x != 0)
                {
                    OutBuffer ob = new OutBuffer();
                    ob.write(x);
                    ubyte[] compbytes = ob.toBytes();
                    if ((compbytes[0] & 0x80u) == 0) compbytes[0] |= 0x80u;
                    encodedOIDComponent = compbytes[0] ~ encodedOIDComponent;
                    x >>= 7;
                }
                encodedOIDComponent[$-1] &= 0x7Fu;
                this.value ~= encodedOIDComponent;
            }
        }
    }

    ///
    @safe
    unittest
    {
        BERValue bv = new BERValue();
        bv.objectIdentifier = new OID(1u, 30u, 256u, 623485u, 8u);
        // FIXME: I think this unittest fails without .numericArray because I have not designed opCmp() for OID well.
        assert(bv.objectIdentifier.numericArray ==  (new OID(1u, 30u, 256u, 623485u, 8u)).numericArray);
    }

    /**
        Decodes an ObjectDescriptor, which is a string consisting of only
        graphical characters. In fact, ObjectDescriptor is actually implicitly
        just a GraphicString! The formal specification for an ObjectDescriptor
        is:

        $(I ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        GraphicString is just 0x20 to 0x7E, therefore ObjectDescriptor is just
        0x20 to 0x7E.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

        Returns: a string.
        Throws:
            ASN1InvalidValueException = if the encoded value contains any bytes
                outside of 0x20 to 0x7E.
    */
    override public @property @system
    string objectDescriptor()
    {
        foreach (character; this.value)
        {
            if ((!character.isGraphical) && (character != ' '))
            {
                throw new ASN1InvalidValueException
                    ("Object descriptor can only contain graphical characters. '"
                    ~ character ~ "' is not graphical.");
            }
        }
        return cast(string) this.value;
    }

    /**
        Encodes an ObjectDescriptor, which is a string consisting of only
        graphical characters. In fact, ObjectDescriptor is actually implicitly
        just a GraphicString! The formal specification for an ObjectDescriptor
        is:

        $(I ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        GraphicString is just 0x20 to 0x7E, therefore ObjectDescriptor is just
        0x20 to 0x7E.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

        Throws:
            ASN1InvalidValueException = if the string value contains any
                character outside of 0x20 to 0x7E, which means any control
                characters or DELETE.
    */
    override public @property @system
    void objectDescriptor(string value)
    {
        foreach (character; value)
        {
            if ((!character.isGraphical) && (character != ' '))
            {
                throw new ASN1InvalidValueException
                    ("Object descriptor can only contain graphical characters. '"
                    ~ character ~ "' is not graphical.");
            }
        }
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.objectDescriptor = "qwert yuiop";
        assert(bv.objectDescriptor == "qwert yuiop");
    }
    // TODO: Negative unit tests

    /* REVIEW:
        Is there some way to abstract the types into the parent class?
    */
    /**
        Decodes an EXTERNAL, which is a constructed data type, defined in 
        the $(LINK2 https://www.itu.int, 
            International Telecommunications Union)'s 
        $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines EXTERNAL as:

        $(I
            EXTERNAL := [UNIVERSAL 8] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER } },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 2.

        Returns: an External, defined in types.universal.external.
        Throws:
            ASN1SizeException = if encoded EmbeddedPDV has too few or too many
                elements, or if syntaxes or context-negotiation element has
                too few or too many elements.
            ASN1ValueTooBigException = if encoded INTEGER is too large to decode.
            ASN1InvalidValueException = if encoded ObjectDescriptor contains
                invalid characters.
            ASN1InvalidIndexException = if encoded value selects a choice for 
                identification or uses an unspecified index for an element in
                syntaxes or context-negotiation, or if an unspecified element
                of EMBEDDED PDV itself is referenced by an out-of-range 
                context-specific index. (See $(D_INLINECODE ASN1InvalidIndexException).)
    */
    // NOTE: If integer properties are marked @trusted, this can be @safe
    override public @property @system
    External external()
    {
        BERValue[] bvs = this.sequence;
        if (bvs.length < 2 || bvs.length > 3)
            throw new ASN1ValueSizeException
            ("Improper number of elements in EXTERNAL type.");

        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();
        External ext = External();

        foreach (bv; bvs)
        {
            switch (bv.type)
            {
                case (0x80u): // identification
                {
                    BERValue identificationBV = new BERValue(bv.value);
                    switch(identificationBV.type)
                    {
                        case (0x80u): // syntax
                        {
                            identification.syntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x81u): // presentation-context-id
                        {
                            identification.presentationContextID = identificationBV.integer!long;
                            break;
                        }
                        case (0x82u): // context-negotiation
                        {
                            // REVIEW: Should this be split off into a separate function?
                            ASN1ContextNegotiation contextNegotiation = ASN1ContextNegotiation();
                            BERValue[] cns = identificationBV.sequence;
                            if (cns.length != 2)
                                throw new ASN1ValueTooBigException
                                ("Invalid number of elements in EXTERNAL.identification.context-negotiation");
                            
                            foreach (cn; cns)
                            {
                                switch (cn.type)
                                {
                                    case (0x80u): // presentation-context-id
                                    {
                                        contextNegotiation.presentationContextID = cn.integer!long;
                                        break;
                                    }
                                    case (0x81u): // transfer-syntax
                                    {
                                        contextNegotiation.transferSyntax = cn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new ASN1InvalidIndexException
                                        ("Invalid EXTERNAL.identification.context-negotiation tag.");
                                    }
                                }
                            }
                            identification.contextNegotiation = contextNegotiation;
                            break;
                        }
                        default:
                        {
                            throw new ASN1InvalidIndexException
                            ("Invalid EXTERNAL.identification choice.");
                        }
                    }
                    ext.identification = identification;
                    break;
                }
                case (0x81u): // data-value-descriptor
                {
                    ext.dataValueDescriptor = bv.objectDescriptor;
                    break;
                }
                case (0x82u): // data-value
                {
                    ext.dataValue = bv.octetString;
                    break;
                }
                default:
                {
                    throw new ASN1InvalidIndexException
                    ("Invalid EXTERNAL context-specific tag.");
                }
            }
        }
        return ext;
    }

    /**
        Encodes an EXTERNAL, which is a constructed data type, defined in 
        the $(LINK2 https://www.itu.int, 
            International Telecommunications Union)'s 
        $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines EXTERNAL as:

        $(I
        EXTERNAL := [UNIVERSAL 8] IMPLICIT SEQUENCE {
            identification CHOICE {
                syntax OBJECT IDENTIFIER,
                presentation-context-id INTEGER,
                context-negotiation SEQUENCE {
                    presentation-context-id INTEGER,
                    transfer-syntax OBJECT IDENTIFIER } },
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 2.

        Throws:
            ASN1ValueTooBigException = if encoded INTEGER is too large to decode
            ASN1InvalidValueException = if encoded ObjectDescriptor contains
                invalid characters.
    */
    // NOTE: If integer properties are marked @trusted, this can be @safe
    override public @property @system
    void external(External value)
    {
        BERValue identification = new BERValue();
        identification.type = 0x80u; // CHOICE is EXPLICIT, even with automatic tagging.

        BERValue identificationValue = new BERValue();
        if (!(value.identification.syntax.isNull))
        {
            identificationValue.type = 0x80u;
            identificationValue.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.contextNegotiation.isNull))
        {
            BERValue presentationContextID = new BERValue();
            presentationContextID.type = 0x80u;
            presentationContextID.integer = value.identification.contextNegotiation.presentationContextID;
            
            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x81u;
            transferSyntax.objectIdentifier = value.identification.contextNegotiation.transferSyntax;
            
            identificationValue.type = 0x82u;
            identificationValue.sequence = [ presentationContextID, transferSyntax ];
        }
        else // it must be the presentationContextID INTEGER
        {
            identificationValue.type = 0x81u;
            identificationValue.integer!long = value.identification.presentationContextID;
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationValue;

        BERValue dataValueDescriptor = new BERValue();
        dataValueDescriptor.type = 0x81u; // Primitive ObjectDescriptor
        dataValueDescriptor.objectDescriptor = value.dataValueDescriptor;

        BERValue dataValue = new BERValue();
        dataValue.type = 0x82u;
        dataValue.octetString = value.dataValue;

        this.sequence = [ identification, dataValueDescriptor, dataValue ];
    }

    ///
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        External ext = External();
        ext.identification = id;
        ext.dataValueDescriptor = "external";
        ext.dataValue = [ 0x01u, 0x02u, 0x03u, 0x04u ];

        BERValue bv = new BERValue();
        bv.type = 0x08u;
        bv.external = ext;
        assert(bv.toBytes() == [ 
            0x08u, 0x1Cu, 0x80u, 0x0Au, 0x81u, 0x08u, 0x00u, 0x00u, 
            0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x1Bu, 0x81u, 0x08u, 
            0x65u, 0x78u, 0x74u, 0x65u, 0x72u, 0x6Eu, 0x61u, 0x6Cu, 
            0x82u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u 
        ]);

        External x = bv.external;
        assert(x.identification.presentationContextID == 27L);
        assert(x.dataValueDescriptor == "external");
        assert(x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]);
    }

    /**
        Decodes a float or double. This can never decode directly to a
        real type, because of the way it works.

        This is admittedly a pretty slow function, so I would recommend
        avoiding it, if possible. Also, because it is so complex, it is
        highly likely to have bugs, so for that reason as well, I highly
        recommand against encoding or decoding REALs if you do not have
        to; try using INTEGER instead.

        For the BER-encoded REAL, a value of 0x40 means "positive infinity,"
        a value of 0x41 means "negative infinity." An empty value means
        exactly zero. A value whose first byte starts with two cleared bits
        encodes the real as a string of characters, where the latter nybble
        takes on values of 0x1, 0x2, or 0x3 to indicate that the string
        representation conforms to
        $(LINK2 , ISO 6093) Numeric Representation 1, 2, or 3 respectively.
        
        If the first bit is set, then the first byte is an "information block"
        that describes the binary encoding of the REAL on the subsequent bytes.
        If bit 6 is set, the value is negative; if clear, the value is 
        positive. Bits 4 and 5 determine the base, with a value of 0 indicating
        a base of 2, a value of 1 indicating a base of 8, and a value of 2
        indicating a base of 16. Bits 2 and 3 indicates that the value should
        be scaled by 1, 2, 4, or 8 for values of 1, 2, 3, or 4 respectively.
        Bits 0 and 1 determine how the exponent is encoded, with 0 indicating
        that the exponent is encoded as a signed byte on the second byte of
        the value, with 1 indicating that the exponent is encoded as a signed
        short on the subsequent two bytes, with 2 indicating that the exponent
        is encoded as a three-byte signed integer on the subsequent three 
        bytes, and with 4 indicating that the subsequent byte encodes the 
        unsigned length of the exponent on the following bytes. The remaining
        bytes encode an unsigned integer, N, such that mantissa is equal to
        sign * N * 2^scale.

        Throws:
            ConvException = if character-encoding cannot be converted to
                the selected floating-point type, T.
            ConvOverflowException = if the character-encoding encodes a 
                number that is too big for the selected floating-point
                type to express.
            ASN1ValueTooSmallException = if the binary-encoding contains fewer
                bytes than the information byte purports.
            ASN1ValueTooBigException = if the binary-encoded mantissa is too 
                big to be expressed by an unsigned long integer.
            ASN1InvalidValueException = if both bits indicating the base in the
                information byte of a binary-encoded REAL's information byte 
                are set, which would indicate an invalid base.
    */
    public @property @system
    T realType(T)() if (is(T == float) || is(T == double))
    {
        // import std.array : split;
        import std.conv : ConvException, ConvOverflowException, to;

        if (this.length == 0) return cast(T) 0.0;

        switch (this.value[0] & 0b_1100_0000)
        {
            case (0b_0100_0000u):
            {
                return ((this.value[0] & 0b_0011_1111u) ? T.infinity : -T.infinity);
            }
            case (0b_0000_0000u): // Character Encoding
            {
                string chars = cast(string) this.value[1 .. $];

                try 
                {
                    return to!(T)(chars);
                }
                catch (ConvOverflowException coe)
                {
                    throw new ASN1ValueTooBigException
                    ("Character-encoded REAL is too large to translate to a native floating-point type.");
                }
                catch (ConvException ce)
                {
                    throw new ASN1ValueTooBigException
                    ("Character-encoded REAL could not be decoded to a native floating-point type.");
                }

                // size_t i;
                // ptrdiff_t decimalPointIndex = -1;
                // ptrdiff_t exponentOperatorIndex = -1; // 'e' or 'E'

                // if (chars[0] >= '0' && chars[0] <= '9')
                // {
                //     ret = 0.0;
                // }
                // else if (chars[0] == '+')
                // {
                //     ret = 0.0;
                //     i++;
                // }
                // else if (chars[0] == '.')
                // {
                //     ret = 0.0;
                //     i++;
                //     decimalPointIndex = 0;
                // }
                // else
                // {
                //     ret = -0.0;
                //     i++;
                // }

                // while (i < chars.length)
                // {
                //     if (exponentOperatorEncountered && (chars[i] == 'e' || chars[i] == 'E'))
                //         throw new BERException
                //         ("Invalid character-encoded REAL; has two or more 'E's.");
                //     if (exponentOperatorEncountered && chars[i] == '.')
                //         throw new BERException
                //         ("Invalid character-encoded REAL; has two or more '.'s.");
                // }

                // long mantissa;
                // try 
                // {
                //     mantissa = exponentOperatorEncountered ? 
                // }
                // catch (ConvOverflowException)
                // {

                // }
                // catch (ConvException ce)
                // {

                // }

                // switch (this.value[0] & 0b_0011_1111)
                // {
                //     case (0b_0000_0001): // NR1
                //     {
                //         // 3, -1, +1000
                //     }
                //     case (0b_0000_0010): // NR2
                //     {
                //         // 3.0, -1.3, -.3
                //     }
                //     case (0b_0000_0011): // NR3
                //     {
                //         // 3.0E1, 123E+100
                //     }
                //     default:
                //     {
                //         throw new BERException
                //         ("Invalid Numeric Representation for REAL selected.");
                //     }
                // }
            }
            case 0b_1000_0000u, 0b_1100_0000u: // Binary Encoding
            {
                ulong mantissa;
                long exponent;
                ubyte scale;
                ubyte base;
                ASN1RealBinaryEncodingBase realBinaryEncodingBase = ASN1RealBinaryEncodingBase.base2;

                // There must be at least one information byte and one exponent byte.
                if (this.length < 2)
                    throw new ASN1ValueTooSmallException
                    ("REAL value has too few bytes. Only an information byte was found.");

                switch (this.value[0] & 0b00000011u)
                {
                    case 0b00000000u: // Exponent on the following octet
                    {
                        /*
                            this.value[1] has to be cast to a byte first so that it
                            acquires a sign.
                        */
                        exponent = cast(long) cast(byte) this.value[1];

                        if (this.length - 2u > 8u)
                            throw new ASN1ValueTooBigException
                            ("REAL mantissa is too big for this encoder.");

                        ubyte m = 0x02u;
                        while (m < this.length)
                        {
                            mantissa <<= 8;
                            mantissa += this.value[m];
                            m++;
                        }

                        break;
                    }
                    case 0b00000001u: // Exponent on the following two octets
                    {
                        if (this.length == 2u)
                            throw new ASN1ValueTooSmallException
                            ("REAL value has too few bytes.");

                        // void[2] exponentBytes = *cast(void[2] *) &(this.value[1]);
                        ubyte[] exponentBytes = this.value[1 .. 3].dup;
                        version (LittleEndian)
                        {
                            reverse(exponentBytes);
                        }
                        exponent = cast(long) (*cast(short *) exponentBytes.ptr);

                        if (this.length - 3u > 8u)
                            throw new ASN1ValueTooBigException
                            ("REAL mantissa is too big for this encoder.");

                        // REVIEW: There is probably a better way to do this.
                        ubyte m = 0x02u;
                        version (LittleEndian)
                        {
                            while (m < this.length)
                            {
                                mantissa <<= 8;
                                mantissa += this.value[m];
                                m++;
                            }
                        }
                        version (BigEndian)
                        {
                            while (this.length - m > 0u)
                            {
                                mantissa <<= 8;
                                mantissa += this.value[m];
                                m--;
                            }
                        }

                        break;
                    }
                    case 0b00000010: // Exponent on the following three octets
                    {
                        if (this.length == 4u)
                            throw new ASN1ValueTooSmallException
                            ("REAL value has too few bytes.");

                        exponent = cast(long) ((*cast(int *) cast(void[4] *) &(this.value[1])) & 0x00FFFFFF);

                        if (this.length - 4u > 8u)
                            throw new ASN1ValueTooBigException
                            ("REAL mantissa is too big for this encoder.");

                        ubyte m = 0x03u;
                        while (m < this.length)
                        {
                            mantissa <<= 8;
                            mantissa += this.value[m];
                            m++;
                        }
                        break;
                    }
                    case 0b00000011: // Complicated
                    {
                        if (this.length == 1u)
                            throw new ASN1ValueTooSmallException
                            ("REAL value has too few bytes.");
                        
                        ubyte exponentLength = this.value[1];

                        if (this.length == (exponentLength - 0x01u))
                            throw new ASN1ValueTooSmallException
                            ("REAL value has too few bytes.");

                        if (exponentLength > 0x08u)
                            throw new ASN1ValueTooBigException
                            ("REAL value exponent is too big.");

                        ubyte i = 0x00u;
                        while (i < exponentLength)
                        {
                            exponent <<= 8;
                            exponent += this.value[i];
                            i++;
                        }

                        if (this.length - 1u - exponentLength > 8u)
                            throw new ASN1ValueTooBigException
                            ("REAL mantissa is too big for this encoder.");

                        ubyte m = 0x01u;
                        while (m < this.length)
                        {
                            mantissa <<= 8;
                            mantissa += this.value[m];
                            m++;
                        }
                        break;
                    }
                    default:
                    {
                        assert(0, "Impossible binary exponent encoding on REAL type");
                    }
                }

                switch (this.value[0] & 0b_0011_0000)
                {
                    case (0b_0000_0000): // Base 2
                    {
                        base = 0x02u;
                        break;
                    }
                    case (0b_0000_0001): // Base 8
                    {
                        base = 0x08u;
                        break;
                    }
                    case (0b_0000_0010): // Base 16
                    {
                        base = 0x10u;
                        break;
                    }
                    default:
                    {
                        throw new ASN1InvalidValueException
                        ("Invalid binary-encoded REAL base");
                    }
                }

                scale = ((this.value[0] & 0b_0000_1100u) >> 2);

                return (
                    ((this.value[0] & 0b_0100_0000u) ? -1 : 1) *
                    mantissa *
                    2^^scale *
                    (cast(T) base)^^exponent // base needs to be cast
                );
            }
            default:
            {
                assert(0, "Impossible information byte value appeared!");
            }
        }
    }

    /**
        Encodes a float or double. This can never decode directly to a
        real type, because of the way it works.

        This is admittedly a pretty slow function, so I would recommend
        avoiding it, if possible. Also, because it is so complex, it is
        highly likely to have bugs, so for that reason as well, I highly
        recommand against encoding or decoding REALs if you do not have
        to; try using INTEGER instead.

        For the BER-encoded REAL, a value of 0x40 means "positive infinity,"
        a value of 0x41 means "negative infinity." An empty value means
        exactly zero. A value whose first byte starts with two cleared bits
        encodes the real as a string of characters, where the latter nybble
        takes on values of 0x1, 0x2, or 0x3 to indicate that the string
        representation conforms to
        $(LINK2 , ISO 6093) Numeric Representation 1, 2, or 3 respectively.
        
        If the first bit is set, then the first byte is an "information block"
        that describes the binary encoding of the REAL on the subsequent bytes.
        If bit 6 is set, the value is negative; if clear, the value is 
        positive. Bits 4 and 5 determine the base, with a value of 0 indicating
        a base of 2, a value of 1 indicating a base of 8, and a value of 2
        indicating a base of 16. Bits 2 and 3 indicates that the value should
        be scaled by 1, 2, 4, or 8 for values of 1, 2, 3, or 4 respectively.
        Bits 0 and 1 determine how the exponent is encoded, with 0 indicating
        that the exponent is encoded as a signed byte on the second byte of
        the value, with 1 indicating that the exponent is encoded as a signed
        short on the subsequent two bytes, with 2 indicating that the exponent
        is encoded as a three-byte signed integer on the subsequent three 
        bytes, and with 4 indicating that the subsequent byte encodes the 
        unsigned length of the exponent on the following bytes. The remaining
        bytes encode an unsigned integer, N, such that mantissa is equal to
        sign * N * 2^scale.

        Throws:
            ASN1InvalidValueException = if an attempt to encode NaN is made.
    */
    // REVIEW: Doth mine eyes deceive me? Is this actually nothrow?
    public @property @system
    void realType(T)(T value)
    if (is(T == float) || is(T == double))
    {
        import std.bitmanip : DoubleRep, FloatRep;

        bool positive = true;
        real significand;
        ASN1RealEncodingScale scalingFactor = ASN1RealEncodingScale.scale0;
        ASN1RealEncodingBase base = ASN1RealEncodingBase.base2;
        ASN1RealBinaryEncodingBase ASN1realBinaryEncodingBase = ASN1RealBinaryEncodingBase.base2;
        short exponent = 0;

        if (value == T.nan)
        {
            throw new ASN1InvalidValueException("ASN1 cannot encode NaN");
        }
        else if (value == T.infinity)
        {
            this.value = [ 0x01u, 0x40u ];
        }
        else if (value == -T.infinity)
        {
            this.value = [ 0x01u, 0x41u ];
        }

        /*
            IEEE floating-point types only store the fractional part of
            the significand, because there is an implicit 1 prior to the
            fractional part. To retrieve the actual significand encoded,
            we flip the bit that comes just before the most significant
            bit of the fractional part of the number.

            Per the IEEE specifications, the exponent of a floating-point
            type is stored with a bias, meaning that the exponent counts
            up from a negative number, the reaches zero at the bias. We
            subtract the bias from the raw binary exponent to get the
            actual exponent encoded in the IEEE floating-point number.
            We then subtract the number of bits in the fraction from the
            exponent, which is equivalent to having had multiplied the
            fraction enough to have made it an integer represented by the
            same sequence of bits.
        */
        static if (is(T == double))
        {
            DoubleRep valueUnion = DoubleRep(value);
            significand = (valueUnion.fraction | 0x0010000000000000u); // Flip bit #53
        }
        static if (is(T == float))
        {
            FloatRep valueUnion = FloatRep(value);
            significand = (valueUnion.fraction | 0x00800000u); // Flip bit #24
        }

        // IEEE floating-point types use a set first bit to indicate a negative.
        positive = (valueUnion.sign ? false : true);

        // See comment below.
        exponent = cast(short)
            (valueUnion.exponent - valueUnion.bias - valueUnion.fractionBits);

        /*
            However, by doing this, we sometimes underflow the exponent.
            Fortunately, we can tell we have underflowed the exponent if
            the exponent is greater than
            typeof(exponent).max - fractionBits,
            because in D, as with many other similar languages, overflows
            and underflows are "wrapped," meaning that, for example,
            uint.max + 1 = uint.min and uint.min - 1 = uint.max.
            To correct the underflow... we overflow! This is done in the
            while loop in each of the two following static ifs. The
            exponent is incremented until it is as though it never
            underflowed in the first place, each time dividing the
            significand by two, such that the same number is still
            represented by the combination of the significand and
            exponent.

            Note that the valueUnion.fractionBits must be cast to
            typeof(exponent) prior to being used in the comparison,
            otherwise all values in the while loop will be promoted to
            ints, which will prevent the necessary overflow from
            happening when it should.
        */
        while (exponent > (short.max - cast(short) valueUnion.fractionBits))
        {
            significand /= 2.0; // You can't << 2 here, because significand is a real.
            exponent++;
        }

        /* FIXME:
            Converting from a significand of type real to uint or ulong means that an overflow
            exception is highly possible.
        */
        ubyte[] exponentBytes;
        exponentBytes.length = short.sizeof;
        *cast(short *)exponentBytes.ptr = exponent;
        version (LittleEndian)
        {
            reverse(exponentBytes);
        }
        
        ubyte[] significandBytes;
        significandBytes.length = ulong.sizeof;
        *cast(ulong *)significandBytes.ptr = cast(ulong) significand;
        version (LittleEndian)
        {
            reverse(significandBytes);
        }

        ubyte infoByte =
            0x80u | // First bit gets set for base2, base8, or base16 encoding
            (positive ? 0x00u : 0x40u) | // 1 = negative, 0 = positive
            realBinaryEncodingBase | // Bitmask specifying base
            ASN1RealEncodingScales.scale0 |
            ASN1RealExponentEncoding.following2Octets;

        this.value = (infoByte ~ exponentBytes ~ significandBytes);
    }

    // TODO: Test a LOT of values here.
    ///
    @system
    unittest
    {
        import std.math : approxEqual;
        float f = 22.86;
        double d = 0.00583;
        BERValue bvf = new BERValue();
        BERValue bvd = new BERValue();
        bvf.realType!float = f;
        bvd.realType!double = d;
        assert(approxEqual(bvf.realType!float, f));
        assert(approxEqual(bvf.realType!double, f));
        assert(approxEqual(bvd.realType!float, d));
        assert(approxEqual(bvd.realType!double, d));
    }

    // TODO: Review, test, and mark as @trusted
    /**
        Decodes an integer from an ENUMERATED type. In BER, an ENUMERATED
        type is encoded the exact same way that an INTEGER is.

        Returns: any chosen signed integral type
        Throws:
            ASN1ValueTooBigException = if the value is too big to decode
                to a signed integral type.
    */
    public @property @system
    T enumerated(T)()
    if (isIntegral!T && isSigned!T)
    {
        /* NOTE:
            this.value must be duplicated; if it is not, the reverse() operation
            below reverses this.value, which persists until the next decode!
        */
        ubyte[] value = this.value.dup;
        if (value.length > T.sizeof)
            throw new ASN1ValueTooBigException
            ("ENUMERATED is too big to be decoded.");

        /* NOTE:
            Because the BER ENUMERATED is stored in two's complement form, you 
            can't just apppend 0x00u to the big end of it until it is as long
            as T in bytes, then cast to T. Instead, you have to first determine
            if the encoded integer is negative or positive. If it is negative,
            then you actually want to append 0xFFu to the big end until it is
            as big as T, so you get the two's complement form of whatever T
            you choose.

            The line immediately below this determines whether the padding byte
            should be 0xFF or 0x00 based on the most significant bit of the 
            most significant byte (which, since BER encodes big-endian, will
            always be the first byte). If set (1), the number is negative, and
            hence, the padding byte should be 0xFF. If not, it is positive,
            and the padding byte should be 0x00.
        */
        ubyte paddingByte = ((this.value[0] & 0x80u) ? 0xFFu : 0x00u);
        while (value.length < T.sizeof)
            value = (paddingByte ~ value);

        version (LittleEndian)
        {
            reverse(value);
        }
        return *cast(T *) value.ptr;
    }

    // TODO: Review, test, and mark as @trusted
    /**
        Encodes an ENUMERATED type from an integer. In BER, an ENUMERATED
        type is encoded the exact same way that an INTEGER is.
    */
    public @property @system
    void enumerated(T)(T value)
    {
        ubyte[] ub;
        ub.length = T.sizeof;
        *cast(T *)&ub[0] = value;
        version (LittleEndian)
        {
            reverse(ub);
        }
        this.value = ub[0 .. $];
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();

        // Tests for zero
        bv.enumerated!byte = 0;
        assert(bv.enumerated!byte == 0);
        assert(bv.enumerated!short == 0);
        assert(bv.enumerated!int == 0);
        assert(bv.enumerated!long == 0L);

        bv.enumerated!short = 0;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assert(bv.enumerated!short == 0);
        assert(bv.enumerated!int == 0);
        assert(bv.enumerated!long == 0L);

        bv.enumerated!int = 0;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assert(bv.enumerated!int == 0);
        assert(bv.enumerated!long == 0L);

        bv.enumerated!long = 0L;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!int);
        assert(bv.enumerated!long == 0L);

        // Tests for small positives
        bv.enumerated!byte = 3;
        assert(bv.enumerated!byte == 3);
        assert(bv.enumerated!short == 3);
        assert(bv.enumerated!int == 3);
        assert(bv.enumerated!long == 3L);

        bv.enumerated!short = 5;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assert(bv.enumerated!short == 5);
        assert(bv.enumerated!int == 5);
        assert(bv.enumerated!long == 5L);

        bv.enumerated!int = 7;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assert(bv.enumerated!int == 7);
        assert(bv.enumerated!long == 7L);

        bv.enumerated!long = 9L;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!int);
        assert(bv.enumerated!long == 9L);

        // Tests for small negatives
        bv.enumerated!byte = -3;
        assert(bv.enumerated!byte == -3);
        assert(bv.enumerated!short == -3);
        assert(bv.enumerated!int == -3);
        assert(bv.enumerated!long == -3L);

        bv.enumerated!short = -5;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assert(bv.enumerated!short == -5);
        assert(bv.enumerated!int == -5);
        assert(bv.enumerated!long == -5L);

        bv.enumerated!int = -7;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assert(bv.enumerated!int == -7);
        assert(bv.enumerated!long == -7L);

        bv.enumerated!long = -9L;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!int);
        assert(bv.enumerated!long == -9L);

        // Tests for large positives
        bv.enumerated!short = 20000;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assert(bv.enumerated!short == 20000);
        assert(bv.enumerated!int == 20000);
        assert(bv.enumerated!long == 20000L);

        bv.enumerated!int = 70000;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assert(bv.enumerated!int == 70000);
        assert(bv.enumerated!long == 70000L);

        bv.enumerated!long = 70000L;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!int);
        assert(bv.enumerated!long == 70000L);

        // Tests for large negatives
        bv.enumerated!short = -20000;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assert(bv.enumerated!short == -20000);
        assert(bv.enumerated!int == -20000);
        assert(bv.enumerated!long == -20000L);

        bv.enumerated!int = -70000;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assert(bv.enumerated!int == -70000);
        assert(bv.enumerated!long == -70000L);

        bv.enumerated!long = -70000L;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!int);
        assert(bv.enumerated!long == -70000L);

        // Tests for maximum values
        bv.enumerated!byte = byte.max;
        assert(bv.enumerated!byte == byte.max);
        assert(bv.enumerated!short == byte.max);
        assert(bv.enumerated!int == byte.max);
        assert(bv.enumerated!long == byte.max);

        bv.enumerated!short = short.max;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assert(bv.enumerated!short == short.max);
        assert(bv.enumerated!int == short.max);
        assert(bv.enumerated!long == short.max);

        bv.enumerated!int = int.max;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assert(bv.enumerated!int == int.max);
        assert(bv.enumerated!long == int.max);

        bv.enumerated!long = long.max;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!int);
        assert(bv.enumerated!long == long.max);

        // Tests for minimum values
        bv.enumerated!byte = byte.min;
        assert(bv.enumerated!byte == byte.min);
        assert(bv.enumerated!short == byte.min);
        assert(bv.enumerated!int == byte.min);
        assert(bv.enumerated!long == byte.min);

        bv.enumerated!short = short.min;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assert(bv.enumerated!short == short.min);
        assert(bv.enumerated!int == short.min);
        assert(bv.enumerated!long == short.min);

        bv.enumerated!int = int.min;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assert(bv.enumerated!int == int.min);
        assert(bv.enumerated!long == int.min);

        bv.enumerated!long = long.min;
        assertThrown!ASN1ValueTooBigException(bv.enumerated!byte);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!short);
        assertThrown!ASN1ValueTooBigException(bv.enumerated!int);
        assert(bv.enumerated!long == long.min);
    }

    ///
    /**
        Decodes an EMBEDDED PDV, which is a constructed data type, defined in 
            the $(LINK2 https://www.itu.int, 
                International Telecommunications Union)'s 
            $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines EMBEDDED PDV as:

        $(I
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
            (WITH COMPONENTS { ... , data-value-descriptor ABSENT })
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 5.

        Throws:
            ASN1SizeException = if encoded EmbeddedPDV has too few or too many
                elements, or if syntaxes or context-negotiation element has
                too few or too many elements.
            ASN1ValueTooBigException = if encoded INTEGER is too large to decode.
            ASN1InvalidValueException = if encoded ObjectDescriptor contains
                invalid characters.
            ASN1InvalidIndexException = if encoded value selects a choice for 
                identification or uses an unspecified index for an element in
                syntaxes or context-negotiation, or if an unspecified element
                of EMBEDDED PDV itself is referenced by an out-of-range 
                context-specific index. (See $(D_INLINECODE ASN1InvalidIndexException).)
    */
    // NOTE: If the integer properties are marked @trusted, this can be @safe.
    override public @property @system
    EmbeddedPDV embeddedPresentationDataValue()
    {
        BERValue[] bvs = this.sequence;
        if (bvs.length < 2 || bvs.length > 3)
            throw new ASN1ValueSizeException
            ("Improper number of elements in EMBEDDED PDV type.");

        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();
        EmbeddedPDV pdv = EmbeddedPDV();

        foreach (bv; bvs)
        {
            switch (bv.type)
            {
                case (0x80u): // identification
                {
                    BERValue identificationBV = new BERValue(bv.value);
                    switch (identificationBV.type)
                    {
                        case (0x80u): // syntaxes
                        {
                            ASN1ContextSwitchingTypeSyntaxes syntaxes = ASN1ContextSwitchingTypeSyntaxes();
                            BERValue[] syns = identificationBV.sequence;
                            if (syns.length != 2)
                                throw new ASN1ValueSizeException
                                ("Invalid number of elements in EMBEDDED PDV.identification.syntaxes");

                            foreach (syn; syns)
                            {
                                switch (syn.type)
                                {
                                    case (0x80u): // abstract
                                    {
                                        syntaxes.abstractSyntax = syn.objectIdentifier;
                                        break;
                                    }
                                    case (0x81): // transfer
                                    {
                                        syntaxes.transferSyntax = syn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new ASN1InvalidIndexException
                                        ("Invalid EMBEDDED PDV.identification.syntaxes tag.");
                                    }
                                }
                            }
                            identification.syntaxes = syntaxes;
                            break;
                        }
                        case (0x81u): // syntax
                        {
                            identification.syntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x82u): // presentation-context-id
                        {
                            identification.presentationContextID = identificationBV.integer!long;
                            break;
                        }
                        case (0x83u): // context-negotiation
                        {
                            // REVIEW: Should this be split off into a separate function?
                            ASN1ContextNegotiation contextNegotiation = ASN1ContextNegotiation();
                            BERValue[] cns = identificationBV.sequence;
                            if (cns.length != 2)
                                throw new ASN1ValueTooBigException
                                ("Invalid number of elements in EMBEDDED PDV.identification.context-negotiation");
                            
                            foreach (cn; cns)
                            {
                                switch (cn.type)
                                {
                                    case (0x80u): // presentation-context-id
                                    {
                                        contextNegotiation.presentationContextID = cn.integer!long;
                                        break;
                                    }
                                    case (0x81u): // transfer-syntax
                                    {
                                        contextNegotiation.transferSyntax = cn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new ASN1InvalidIndexException
                                        ("Invalid EMBEDDED PDV.identification.context-negotiation tag.");
                                    }
                                }
                            }
                            identification.contextNegotiation = contextNegotiation;
                            break;
                        }
                        case (0x84u): // transfer-syntax
                        {
                            identification.transferSyntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x85u): // fixed
                        {
                            identification.fixed = true;
                            break;
                        }
                        default:
                        {
                            throw new ASN1InvalidIndexException
                            ("Invalid EMBEDDED PDV.identification choice.");
                        }
                    }
                    pdv.identification = identification;
                    break;
                }
                case (0x81u): // data-value-descriptor
                {
                    pdv.dataValueDescriptor = bv.objectDescriptor;
                    break;
                }
                case (0x82u): // data-value
                {
                    pdv.dataValue = bv.octetString;
                    break;
                }
                default:
                {
                    throw new ASN1InvalidIndexException
                    ("Invalid EMBEDDED PDV context-specific tag.");
                }
            }
        }
        return pdv;
    }

    /**
        Encodes an EMBEDDED PDV, which is a constructed data type, defined in 
            the $(LINK2 https://www.itu.int, 
                International Telecommunications Union)'s 
            $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines EMBEDDED PDV as:

        $(I
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
            (WITH COMPONENTS { ... , data-value-descriptor ABSENT })
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 5.

        Throws:
            ASN1InvalidValueException = if encoded ObjectDescriptor contains
                invalid characters.
    */
    // NOTE: If the integer properties are marked @trusted, this can be @safe.
    override public @property @system
    void embeddedPresentationDataValue(EmbeddedPDV value)
    {
        BERValue identification = new BERValue();
        identification.type = 0x80u; // CHOICE is EXPLICIT, even with automatic tagging.

        BERValue identificationValue = new BERValue();
        if (!(value.identification.syntaxes.isNull))
        {
            BERValue abstractSyntax = new BERValue();
            abstractSyntax.type = 0x81u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x82u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationValue.type = 0x80u;
            identificationValue.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationValue.type = 0x81u;
            identificationValue.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.contextNegotiation.isNull))
        {
            BERValue presentationContextID = new BERValue();
            presentationContextID.type = 0x80u;
            presentationContextID.integer!long = value.identification.contextNegotiation.presentationContextID;
            
            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x81u;
            transferSyntax.objectIdentifier = value.identification.contextNegotiation.transferSyntax;
            
            identificationValue.type = 0x83u;
            identificationValue.sequence = [ presentationContextID, transferSyntax ];
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationValue.type = 0x84u;
            identificationValue.objectIdentifier = value.identification.transferSyntax;
        }
        else if (value.identification.fixed)
        {
            identificationValue.type = 0x85u;
            identificationValue.value = [];
        }
        else // it must be the presentationContextID INTEGER
        {
            identificationValue.type = 0x82u;
            identificationValue.integer!long = value.identification.presentationContextID;
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationValue;

        BERValue dataValueDescriptor = new BERValue();
        dataValueDescriptor.type = 0x81u; // Primitive ObjectDescriptor
        dataValueDescriptor.objectDescriptor = value.dataValueDescriptor;

        BERValue dataValue = new BERValue();
        dataValue.type = 0x82u;
        dataValue.octetString = value.dataValue;

        this.sequence = [ identification, dataValueDescriptor, dataValue ];
    }

    ///
    @system
    unittest
    {
        // import types.universal.embeddedpdv;
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        EmbeddedPDV pdv = EmbeddedPDV();
        pdv.identification = id;
        pdv.dataValueDescriptor = "AAAABBBB";
        pdv.dataValue = [ 0x01u, 0x02u, 0x03u, 0x04u ];

        BERValue bv = new BERValue();
        bv.embeddedPDV = pdv;

        EmbeddedPDV pdv2 = bv.embeddedPresentationDataValue;
        assert(pdv2.identification.presentationContextID == 27L);
        assert(pdv2.dataValueDescriptor == "AAAABBBB");
        assert(pdv2.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]);
    }

    /**
        Decodes the value to UTF-8 characters.

        Throws:
            UTF8Exception if it does not decode correctly.
    */
    override public @property @system
    string unicodeTransformationFormat8String()
    {
        return cast(string) this.value;
    }

    /**
        Encodes a UTF-8 string to bytes. No checks are performed.
    */
    override public @property @system nothrow
    void unicodeTransformationFormat8String(string value)
    {
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.utf8String = "henlo borthers";
        assert(bv.utf8String == "henlo borthers");
    }

    /**
        Decodes a RELATIVE OBJECT IDENTIFIER.
        See source/types/universal/objectidentifier.d for information about
        the ObjectIdentifier class (aliased as "OID").

        The RELATIVE OBJECT IDENTIFIER's numbers are encoded in base-128
        on the least significant 7 bits of each byte. For these bytes, the most
        significant bit is set if the next byte continues the encoding of the
        current OID number. In other words, the bytes encoding each number
        always end with a byte whose most significant bit is cleared.

        Standards:
            $(LINK2 http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660)
    */
    // REVIEW: Can this be nothrow?
    // FIXME: change number sizes to size_t and add overflow checking.
    override public @property @safe
    RelativeOID relativeObjectIdentifier()
    {
        ulong[] oidComponents = [];

        // The loop below breaks the bytes into components.
        ubyte[][] components;
        ptrdiff_t lastTerminator = 0;
        for (int i = 0; i < this.length; i++)
        {
            if (!(this.value[i] & 0x80u))
            {
                components ~= this.value[lastTerminator .. i+1];
                lastTerminator = i+1;
            }
        }

        // The loop below converts each array of bytes (component) into a ulong, and appends it.
        foreach (component; components)
        {
            oidComponents ~= 0u;
            for (ptrdiff_t i = 0; i < component.length; i++)
            {
                oidComponents[$-1] <<= 7;
                oidComponents[$-1] |= cast(ulong) (component[i] & 0x7Fu);
            }
        }

        return new RelativeOID(oidComponents);
    }

    /**
        Encodes a RELATIVE OBJECT IDENTIFIER.
        See source/types/universal/objectidentifier.d for information about
        the ObjectIdentifier class (aliased as "OID").

        The RELATIVE OBJECT IDENTIFIER's numbers are encoded in base-128
        on the least significant 7 bits of each byte. For these bytes, the most
        significant bit is set if the next byte continues the encoding of the
        current OID number. In other words, the bytes encoding each number
        always end with a byte whose most significant bit is cleared.

        Standards:
            $(LINK2 http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660)
    */
    // REVIEW: Can this be nothrow?
    // TODO: Remove std.outbuffer dependency
    // FIXME: change number sizes to size_t and add overflow checking.
    override public @property @safe
    void relativeObjectIdentifier(RelativeOID value)
    {
        ulong[] oidComponents = value.numericArray();
        foreach (x; oidComponents)
        {
            ubyte[] encodedOIDComponent;
            if (x == 0u) // REVIEW: Could you make this faster by using if (x < 128)?
            {
                this.value ~= 0x00u;
                continue;
            }
            while (x != 0u)
            {
                OutBuffer ob = new OutBuffer();
                ob.write(x);
                ubyte[] compbytes = ob.toBytes();
                if ((compbytes[0] & 0x80u) == 0u) compbytes[0] |= 0x80u;
                encodedOIDComponent = compbytes[0] ~ encodedOIDComponent;
                x >>= 7;
            }
            encodedOIDComponent[$-1] &= 0x7Fu;
            this.value ~= encodedOIDComponent;
        }
    }

    ///
    @safe
    unittest
    {
        BERValue bv = new BERValue();
        bv.relativeObjectIdentifier = new RelativeOID(3uL, 5uL, 7uL, 9uL, 4uL);
        assert(bv.relativeObjectIdentifier.numericArray == [ 3L, 5L, 7L, 9L, 4L ]);
    }

    /**
        Decodes a sequence of BERValues.

        Returns: an array of BERValues.
        Throws:
            ASN1ValueSizeException = if long definite-length is too big to be
                decoded to an unsigned integral type.
            ASN1ValueTooSmallException = if there are fewer value bytes than
                indicated by the length tag.
    */
    public @property @system
    BERValue[] sequence()
    {
        ubyte[] data = this.value.dup;
        BERValue[] result;
        while (data.length > 0u)
            result ~= new BERValue(data);
        return result;
    }

    /**
        Encodes a sequence of BERValues.
    */
    public @property @system
    void sequence(BERValue[] value)
    {
        ubyte[] result;
        foreach (bv; value)
        {
            result ~= cast(ubyte[]) bv;
        }
        this.value = result;
    }

    /**
        Decodes a set of BERValues.

        Returns: an array of BERValues.
        Throws:
            ASN1ValueSizeException = if long definite-length is too big to be
                decoded to an unsigned integral type.
            ASN1ValueTooSmallException = if there are fewer value bytes than
                indicated by the length tag.
    */
    public @property @system
    BERValue[] set()
    {
        ubyte[] data = this.value.dup;
        BERValue[] result;
        while (data.length > 0u)
            result ~= new BERValue(data);
        return result;
    }

    /**
        Encodes a set of BERValues.
    */
    public @property @system
    void set(BERValue[] value)
    {
        ubyte[] result;
        foreach (bv; value)
        {
            result ~= cast(ubyte[]) bv;
        }
        this.value = result;
    }

    /**
        Decodes a string, where the characters of the string are limited to
        0 - 9 and space.

        Returns: a string.
        Throws:
            ASN1InvalidValueException = if any character other than 0-9 or
                space is encoded.
    */
    override public @property @system
    string numericString()
    {
        foreach (character; this.value)
        {
            if (!canFind(numericStringCharacters, character))
                throw new ASN1InvalidValueException
                ("NUMERIC STRING only accepts numbers and spaces.");
        }
        return cast(string) this.value;
    }

    /**
        Encodes a string, where the characters of the string are limited to
        0 - 9 and space.

        Throws:
            ASN1InvalidValueException = if any character other than 0-9 or
                space is supplied.
    */
    override public @property @system
    void numericString(string value)
    {
        foreach (character; value)
        {
            if (!canFind(numericStringCharacters, character))
                throw new ASN1InvalidValueException
                ("NUMERIC STRING only accepts numbers and spaces.");
        }
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.numericString = "1234567890";
        assert(bv.numericString == "1234567890");
        assertThrown!ASN1InvalidValueException(bv.numericString = "hey hey");
    }

    /**
        Decodes a string that will only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period, 
        forward slash, colon, equals, and question mark.

        Returns: a string.
        Throws:
            ASN1InvalidValueException = if any character other than a-z, A-Z, 
                0-9, space, apostrophe, parentheses, comma, minus, plus,
                period, forward slash, colon, equals, or question mark are
                encoded.
    */
    override public @property @system
    string printableString()
    {
        foreach (character; this.value)
        {
            if (!canFind(printableStringCharacters, character))
                throw new ASN1InvalidValueException
                ("PrintableString only accepts these characters: " ~ printableStringCharacters);
        }
        return cast(string) this.value;
    }

    /**
        Encodes a string that may only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period, 
        forward slash, colon, equals, and question mark.

        Throws:
            ASN1InvalidValueException = if any character other than a-z, A-Z, 
                0-9, space, apostrophe, parentheses, comma, minus, plus,
                period, forward slash, colon, equals, or question mark are
                supplied.
    */
    override public @property @system
    void printableString(string value)
    {
        foreach (character; value)
        {
            if (!canFind(printableStringCharacters, character))
                throw new ASN1InvalidValueException
                ("PrintableString only accepts these characters: " ~ printableStringCharacters);
        }
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.printableString = "1234567890 asdfjkl";
        assert(bv.printableString == "1234567890 asdfjkl");
        assertThrown!ASN1InvalidValueException(bv.printableString = "\t");
        assertThrown!ASN1InvalidValueException(bv.printableString = "\n");
        assertThrown!ASN1InvalidValueException(bv.printableString = "\0");
        assertThrown!ASN1InvalidValueException(bv.printableString = "\v");
        assertThrown!ASN1InvalidValueException(bv.printableString = "\b");
        assertThrown!ASN1InvalidValueException(bv.printableString = "\r");
        assertThrown!ASN1InvalidValueException(bv.printableString = "\x13");
    }
   
    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array, where each byte is a T.61 character.
    */
    override public @property @safe nothrow
    ubyte[] teletexString()
    {
        // TODO: Validation.
        return this.value;
    }

    /**
        Literally just sets the value bytes.
    */
    override public @property @safe nothrow
    void teletexString(ubyte[] value)
    {
        // TODO: Validation.
        this.value = value;
    }

    ///
    @safe
    unittest
    {
        BERValue bv = new BERValue();
        bv.teletexString = [ 0x01u, 0x03u, 0x05u, 0x07u, 0x09u ];
        assert(bv.teletexString == [ 0x01u, 0x03u, 0x05u, 0x07u, 0x09u ]);
    }

    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array.
    */
    override public @property @safe nothrow
    ubyte[] videotexString()
    {
        // TODO: Validation.
        return this.value;
    }

    /**
        Literally just sets the value bytes.
    */
    override public @property @safe nothrow
    void videotexString(ubyte[] value)
    {
        // TODO: Validation.
        this.value = value;
    }

    ///
    @safe
    unittest
    {
        BERValue bv = new BERValue();
        bv.videotexString = [ 0x01u, 0x03u, 0x05u, 0x07u, 0x09u ];
        assert(bv.videotexString == [ 0x01u, 0x03u, 0x05u, 0x07u, 0x09u ]);
    }

    /**
        Decodes a string that only contains ASCII characters.

        IA5String differs from ASCII ever so slightly: IA5 is international,
        leaving 10 characters up to be locale-specific:

        $(TABLE
            $(TR $(TH Byte) $(TH ASCII Character))
            $(TR $(TD 0x40) $(TD @))
            $(TR $(TD 0x5B) $(TD [))
            $(TR $(TD 0x5C) $(TD \))
            $(TR $(TD 0x5D) $(TD ]))
            $(TR $(TD 0x5E) $(TD ^))
            $(TR $(TD 0x60) $(TD `))
            $(TR $(TD 0x7B) $(TD {))
            $(TR $(TD 0x7C) $(TD /))
            $(TR $(TD 0x7D) $(TD }))
            $(TR $(TD 0x7E) $(TD ~))
        )

        Returns: a string.
        Throws:
            ASN1InvalidValueException = if any enecoded character is not ASCII.
    */
    override public @property @system
    string internationalAlphabetNumber5String()
    {
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isASCII)
                throw new ASN1InvalidValueException
                ("IA5String only accepts ASCII characters.");
        }
        return ret;
    }

    /**
        Encodes a string that may only contain ASCII characters.

        IA5String differs from ASCII ever so slightly: IA5 is international,
        leaving 10 characters up to be locale-specific:

        $(TABLE
            $(TR $(TH Byte) $(TH ASCII Character))
            $(TR $(TD 0x40) $(TD @))
            $(TR $(TD 0x5B) $(TD [))
            $(TR $(TD 0x5C) $(TD \))
            $(TR $(TD 0x5D) $(TD ]))
            $(TR $(TD 0x5E) $(TD ^))
            $(TR $(TD 0x60) $(TD `))
            $(TR $(TD 0x7B) $(TD {))
            $(TR $(TD 0x7C) $(TD /))
            $(TR $(TD 0x7D) $(TD }))
            $(TR $(TD 0x7E) $(TD ~))
        )

        Throws:
            ASN1InvalidValueException = if any enecoded character is not ASCII.
    */
    override public @property @system
    void internationalAlphabetNumber5String(string value)
    {
        foreach (character; value)
        {
            if (!character.isASCII)
                throw new ASN1InvalidValueException
                ("IA5String only accepts ASCII characters.");
        }
        this.value = cast(ubyte[]) value;
    } 

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.ia5String = "Nitro dubs & T-Rix";
        assert(bv.ia5String == "Nitro dubs & T-Rix");
        assertThrown!ASN1InvalidValueException(bv.ia5String = "Nitro dubs \xD7 T-Rix");
    }

    /**
        Decodes a DateTime.
        
        The BER-encoded value is just the ASCII character representation of
        the UTC-formatted timestamp.

        An UTC Timestamp looks like: 
        $(UL
            $(LI 9912312359Z)
            $(LI 991231235959+0200)
        )

        If the first digit of the two-digit year is 7, 6, 5, 4, 3, 2, 1, or 0, 
        meaning that the date refers to the first 80 years of the century, this
        assumes we are talking about the 21st century and prepend '20' when
        creating the ISO Date String. Otherwise, it assumes we are talking 
        about the 20th century, and prepend '19' when creating the string.

        See_Also:
            $(LINK2 https://www.obj-sys.com/asn1tutorial/node15.html, UTCTime)
    */
    // REVIEW: Is there some kind of exception this can throw?
    override public @property @system
    DateTime coordinatedUniversalTime()
    {
        string dt = (((this.value[0] <= '7') ? "20" : "19") ~ cast(string) this.value);
        return DateTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    /**
        Encodes a DateTime.
        
        The BER-encoded value is just the ASCII character representation of
        the UTC-formatted timestamp.

        An UTC Timestamp looks like: 
        $(UL
            $(LI 9912312359Z)
            $(LI 991231235959+0200)
        )

        See_Also:
            $(LINK2 https://www.obj-sys.com/asn1tutorial/node15.html, UTCTime)
    */
    // REVIEW: Is there some kind of exception this can throw?
    override public @property @system
    void coordinatedUniversalTime(DateTime value)
    {
        import std.string : replace;
        this.value = cast(ubyte[]) (value.toISOString()[2 .. $].replace("T", ""));
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.utcTime = DateTime(2017, 10, 3);
        assert(bv.utcTime == DateTime(2017, 10, 3));
    }

    /**
        Decodes a DateTime.

        The BER-encoded value is just the ASCII character representation of
        the $(LINK2 https://www.iso.org/iso-8601-date-and-time-format.html, 
        ISO 8601)-formatted timestamp.

        An ISO-8601 Timestamp looks like: 
        $(UL
            $(LI 19851106210627.3)
            $(LI 19851106210627.3Z)
            $(LI 19851106210627.3-0500)
        )
    */
    // REVIEW: Is there some kind of exception this can throw?
    override public @property @system
    DateTime generalizedTime()
    {
        string dt = cast(string) this.value;
        return DateTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    /**
        Encodes a DateTime.

        The BER-encoded value is just the ASCII character representation of
        the $(LINK2 https://www.iso.org/iso-8601-date-and-time-format.html, 
        ISO 8601)-formatted timestamp.

        An ISO-8601 Timestamp looks like: 
        $(UL
            $(LI 19851106210627.3)
            $(LI 19851106210627.3Z)
            $(LI 19851106210627.3-0500)
        )
    */
    // REVIEW: Is there some kind of exception this can throw?
    override public @property @system
    void generalizedTime(DateTime value)
    {
        import std.string : replace;
        this.value = cast(ubyte[]) (value.toISOString().replace("T", ""));
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.generalizedTime = DateTime(2017, 10, 3);
        assert(bv.generalizedTime == DateTime(2017, 10, 3));
    }

    /**
        Decodes an ASCII string that contains only characters between and 
        including 0x20 and 0x75.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

        Returns: a string.
        Throws:
            ASN1InvalidValueException = if any non-graphical character 
                (including space) is encoded.
    */
    override public @property @system
    string graphicString()
    {
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1InvalidValueException
                ("GraphicString only accepts graphic characters and space.");
        }
        return ret;
    }

    /**
        Encodes an ASCII string that may contain only characters between and 
        including 0x20 and 0x75.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

        Throws:
            ASN1InvalidValueException = if any non-graphical character 
                (including space) is supplied.
    */
    override public @property @system
    void graphicString(string value)
    {
        foreach (character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1InvalidValueException
                ("GraphicString only accepts graphic characters and space.");
        }
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.graphicString = "Nitro dubs & T-Rix";
        assert(bv.graphicString == "Nitro dubs & T-Rix");
        assertThrown!ASN1InvalidValueException(bv.graphicString = "\xD7");
        assertThrown!ASN1InvalidValueException(bv.graphicString = "\t");
        assertThrown!ASN1InvalidValueException(bv.graphicString = "\r");
        assertThrown!ASN1InvalidValueException(bv.graphicString = "\n");
        assertThrown!ASN1InvalidValueException(bv.graphicString = "\b");
        assertThrown!ASN1InvalidValueException(bv.graphicString = "\v");
        assertThrown!ASN1InvalidValueException(bv.graphicString = "\f");
        assertThrown!ASN1InvalidValueException(bv.graphicString = "\0");
    }

    /**
        Decodes a string that only contains characters between and including
        0x20 and 0x7E. (Honestly, I don't know how this differs from
        GraphicalString.)

        Returns: a string.
        Throws:
            ASN1InvalidValueException = if any non-graphical character 
                (including space) is encoded.
    */
    override public @property @system
    string visibleString()
    {
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1InvalidValueException
                ("VisibleString only accepts graphic characters and space.");
        }
        return ret;
    }

    /**
        Encodes a string that only contains characters between and including
        0x20 and 0x7E. (Honestly, I don't know how this differs from
        GraphicalString.)

        Throws:
            ASN1InvalidValueException = if any non-graphical character 
                (including space) is supplied.
    */
    override public @property @system
    void visibleString(string value)
    {
        foreach (character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1InvalidValueException
                ("VisibleString only accepts graphic characters and space.");
        }
        this.value = cast(ubyte[]) value;
    }

    /**
        Decodes a string containing only ASCII characters.

        Returns: a string.
        Throws:
            ASN1InvalidValueException = if any enecoded character is not ASCII.
    */
    override public @property @system
    string generalString()
    {
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isASCII)
                throw new ASN1InvalidValueException
                ("GeneralString only accepts ASCII Characters.");
        }
        return ret;
    }

    /**
        Encodes a string containing only ASCII characters.

        Throws:
            ASN1InvalidValueException = if any enecoded character is not ASCII.
    */
    override public @property @system
    void generalString(string value)
    {
        foreach (character; value)
        {
            if (!character.isASCII)
                throw new ASN1InvalidValueException
                ("GeneralString only accepts ASCII Characters.");
        }
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.generalString = "foin-ass sweatpants from BUCCI \0\n\t\b\v\r\f";
        assert(bv.generalString == "foin-ass sweatpants from BUCCI \0\n\t\b\v\r\f");
        assertThrown!ASN1InvalidValueException(bv.generalString = "\xF5");
    }

    /**
        Decodes a dstring of UTF-32 characters.

        Returns: a string of UTF-32 characters.
        Throws:
            ASN1InvalidValueException = if the encoded bytes is not evenly
                divisible by four.
    */
    override public @property @system
    dstring universalString()
    {
        version (BigEndian)
        {
            return cast(dstring) this.value;
        }
        version (LittleEndian)
        {
            if (this.value.length % 4u)
                throw new ASN1InvalidValueException
                ("Invalid number of bytes for UniversalString. Must be a multiple of 4.");

            dstring ret;
            ptrdiff_t i = 0;
            while (i < this.value.length-3)
            {
                ubyte[] character;
                character.length = 4u;
                character[3] = this.value[i++];
                character[2] = this.value[i++];
                character[1] = this.value[i++];
                character[0] = this.value[i++];
                ret ~= (*cast(dchar *) character.ptr);
            }
            return ret;
        }
        else
        {
            static assert(0, "Could not determine endianness!");
        }
    }

    /**
        Encodes a dstring of UTF-32 characters.
    */
    override public @property @system
    void universalString(dstring value)
    {
        version (BigEndian)
        {
            this.value = cast(ubyte[]) value;
        }
        else version (LittleEndian)
        {
            foreach(character; value)
            {
                ubyte[] charBytes = cast(ubyte[]) *cast(char[4] *) &character;
                reverse(charBytes);
                this.value ~= charBytes;
            }
        }
        else
        {
            static assert(0, "Could not determine endianness!");
        }
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.universalString = "abcd"d;
        assert(bv.universalString == "abcd"d);
    }

    /**
        Decodes a CHARACTER STRING, which is a constructed data type, defined
        in the $(LINK2 https://www.itu.int, 
                International Telecommunications Union)'s 
            $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines CHARACTER as:

        $(I
            CHARACTER STRING ::= [UNIVERSAL 29] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                string-value OCTET STRING }
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 5.

        Returns: an instance of types.universal.CharacterString.
        Throws:
            ASN1SizeException = if encoded CharacterString has too few or too many
                elements, or if syntaxes or context-negotiation element has
                too few or too many elements.
            ASN1ValueTooBigException = if encoded INTEGER is too large to decode.
            ASN1InvalidIndexException = if encoded value selects a choice for 
                identification or uses an unspecified index for an element in
                syntaxes or context-negotiation, or if an unspecified element
                of CharacterString itself is referenced by an out-of-range 
                context-specific index. (See $(D_INLINECODE ASN1InvalidIndexException).)
    */
    // REVIEW: Is this nothrow?
    // NOTE: if the integer properties are marked @trusted, this can be @safe
    override public @property @system
    CharacterString characterString()
    {
        BERValue[] bvs = this.sequence;
        if (bvs.length < 2u || bvs.length > 3u)
            throw new ASN1ValueSizeException
            ("Improper number of elements in CharacterString type.");

        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();
        CharacterString cs = CharacterString();

        foreach (bv; bvs)
        {
            switch (bv.type)
            {
                case (0x80u): // identification
                {
                    BERValue identificationBV = new BERValue(bv.value);
                    switch (identificationBV.type)
                    {
                        case (0x80u): // syntaxes
                        {
                            ASN1ContextSwitchingTypeSyntaxes syntaxes = ASN1ContextSwitchingTypeSyntaxes();
                            BERValue[] syns = identificationBV.sequence;
                            if (syns.length != 2u)
                                throw new ASN1ValueSizeException
                                ("Invalid number of elements in CharacterString.identification.syntaxes");

                            foreach (syn; syns)
                            {
                                switch (syn.type)
                                {
                                    case (0x80u): // abstract
                                    {
                                        syntaxes.abstractSyntax = syn.objectIdentifier;
                                        break;
                                    }
                                    case (0x81): // transfer
                                    {
                                        syntaxes.transferSyntax = syn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new ASN1InvalidIndexException
                                        ("Invalid CharacterString.identification.syntaxes tag.");
                                    }
                                }
                            }
                            identification.syntaxes = syntaxes;
                            break;
                        }
                        case (0x81u): // syntax
                        {
                            identification.syntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x82u): // presentation-context-id
                        {
                            identification.presentationContextID = identificationBV.integer!long;
                            break;
                        }
                        case (0x83u): // context-negotiation
                        {
                            // REVIEW: Should this be split off into a separate function?
                            ASN1ContextNegotiation contextNegotiation = ASN1ContextNegotiation();
                            BERValue[] cns = identificationBV.sequence;
                            if (cns.length != 2u)
                                throw new ASN1ValueSizeException
                                ("Invalid number of elements in CharacterString.identification.context-negotiation");
                            
                            foreach (cn; cns)
                            {
                                switch (cn.type)
                                {
                                    case (0x80u): // presentation-context-id
                                    {
                                        contextNegotiation.presentationContextID = cn.integer!long;
                                        break;
                                    }
                                    case (0x81u): // transfer-syntax
                                    {
                                        contextNegotiation.transferSyntax = cn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new ASN1InvalidIndexException
                                        ("Invalid CharacterString.identification.context-negotiation tag.");
                                    }
                                }
                            }
                            identification.contextNegotiation = contextNegotiation;
                            break;
                        }
                        case (0x84u): // transfer-syntax
                        {
                            identification.transferSyntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x85u): // fixed
                        {
                            identification.fixed = true;
                            break;
                        }
                        default:
                        {
                            throw new ASN1InvalidIndexException
                            ("Invalid CharacterString.identification choice.");
                        }
                    }
                    cs.identification = identification;
                    break;
                }
                case (0x81u): // string-value
                {
                    cs.stringValue = bv.octetString;
                    break;
                }
                default:
                {
                    throw new ASN1InvalidIndexException
                    ("Invalid CharacterString context-specific tag.");
                }
            }
        }
        return cs;
    }

    /**
        Encodes a CHARACTER STRING, which is a constructed data type, defined
        in the $(LINK2 https://www.itu.int, 
                International Telecommunications Union)'s 
            $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines CHARACTER as:

        $(I
            CHARACTER STRING ::= [UNIVERSAL 29] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                string-value OCTET STRING }
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 5.
    */
    // REVIEW: Is this nothrow?
    // NOTE: if the integer properties are marked @trusted, this can be @safe
    override public @property @system
    void characterString(CharacterString value)
    {
        BERValue identification = new BERValue();
        identification.type = 0x80u; // CHOICE is EXPLICIT, even with automatic tagging.

        BERValue identificationValue = new BERValue();
        if (!(value.identification.syntaxes.isNull))
        {
            BERValue abstractSyntax = new BERValue();
            abstractSyntax.type = 0x81u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x82u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationValue.type = 0x80u;
            identificationValue.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationValue.type = 0x81u;
            identificationValue.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.contextNegotiation.isNull))
        {
            BERValue presentationContextID = new BERValue();
            presentationContextID.type = 0x80u;
            presentationContextID.integer!long = value.identification.contextNegotiation.presentationContextID;
            
            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x81u;
            transferSyntax.objectIdentifier = value.identification.contextNegotiation.transferSyntax;
            
            identificationValue.type = 0x83u;
            identificationValue.sequence = [ presentationContextID, transferSyntax ];
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationValue.type = 0x84u;
            identificationValue.objectIdentifier = value.identification.transferSyntax;
        }
        else if (value.identification.fixed)
        {
            identificationValue.type = 0x85u;
            identificationValue.value = [];
        }
        else // it must be the presentationContextID INTEGER
        {
            identificationValue.type = 0x82u;
            identificationValue.integer!long = value.identification.presentationContextID;
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationValue;

        BERValue stringValue = new BERValue();
        stringValue.type = 0x81u;
        stringValue.octetString = value.stringValue;

        this.sequence = [ identification, stringValue ];
    }

    ///
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 63L;

        CharacterString cs = CharacterString();
        cs.identification = id;
        cs.stringValue = [ 'H', 'E', 'N', 'L', 'O' ];

        BERValue bv = new BERValue();
        bv.characterString = cs;

        CharacterString cs2 = bv.characterString;
        assert(cs2.identification.presentationContextID == 63L);
        assert(cs2.stringValue == [ 'H', 'E', 'N', 'L', 'O' ]);
    }

    /**
        Decodes a wstring of UTF-16 characters.

        Returns: an immutable array of UTF-16 characters.
        Throws:
            ASN1InvalidValueException = if the encoded bytes is not evenly
                divisible by two.
    */
    override public @property @system
    wstring basicMultilingualPlaneString()
    {
        version (BigEndian)
        {
            return cast(wstring) this.value;
        }
        version (LittleEndian)
        {
            if (this.value.length % 2u)
                throw new ASN1InvalidValueException
                ("Invalid number of bytes for BMPString. Must be a multiple of 4.");

            wstring ret;
            ptrdiff_t i = 0;
            while (i < this.value.length-1)
            {
                ubyte[] character;
                character.length = 2u;
                character[1] = this.value[i++];
                character[0] = this.value[i++];
                ret ~= (*cast(wchar *) character.ptr);
            }
            return ret;
        }
        else
        {
            static assert(0, "Could not determine endianness!");
        }
    }

    /**
        Encodes a wstring of UTF-16 characters.
    */
    override public @property @system
    void basicMultilingualPlaneString(wstring value)
    {
        version (BigEndian)
        {
            this.value = cast(ubyte[]) value;
        }
        else version (LittleEndian)
        {
            foreach(character; value)
            {
                ubyte[] charBytes = cast(ubyte[]) *cast(char[2] *) &character;
                reverse(charBytes);
                this.value ~= charBytes;
            }
        }
        else
        {
            static assert(0, "Could not determine endianness!");
        }
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.bmpString = "abcd"w;
        assert(bv.bmpString == "abcd"w);
    }

    /**
        Creates an EndOfContent BER Value.
    */
    public @safe @nogc nothrow
    this()
    {
        this.type = 0x00;
        this.value = [];
    }

    /**
        Creates a BERValue from the supplied bytes, inferring that the first
        byte is the type tag. The supplied ubyte[] array is "chomped" by
        reference, so the original array will grow shorter as BERValues are
        generated. 

        Throws:
            ASN1ValueTooSmallException = if the bytes supplied are fewer than
                two (one or zero, in other words), such that no valid BERValue
                can be decoded, or if the length is encoded in indefinite
                form, but the END OF CONTENT octets (two consecutive null
                octets) cannot be found, or if the value is encoded in fewer
                octets than indicated by the length byte.
            ASN1InvalidLengthException = if the length byte is set to 0xFF, 
                which is reserved.
            ASN1ValueTooBigException = if the length cannot be represented by 
                the largest unsigned integer.

        Example:
        ---
        // Decoding looks like:
        BERValue[] result;
        while (bytes.length > 0)
            result ~= new BERValue(bytes);

        // Encoding looks like:
        ubyte[] result;
        foreach (bv; bervalues)
        {
            result ~= cast(ubyte[]) bv;
        }
        ---
    */
    public @system
    this(ref ubyte[] bytes)
    {
        import std.string : indexOf;

        if (bytes.length < 2u)
            throw new ASN1ValueTooSmallException
            ("BER-encoded value terminated prematurely.");
        
        this.type = bytes[0];
        
        // Length
        if (bytes[1] & 0x80u)
        {
            if (bytes[1] & 0x7Fu) // Definite Long or Reserved
            {
                if ((bytes[1] & 0x7Fu) == 0x7Fu) // Reserved
                    throw new ASN1InvalidLengthException
                    ("A BER-encoded length byte of 0xFF is reserved.");

                // Definite Long, if it has made it this far

                if ((bytes[1] & 0x7Fu) > size_t.sizeof)
                    throw new ASN1ValueTooBigException
                    ("BER-encoded value is too big to decode.");

                version (D_LP64)
                {
                    ubyte[] lengthBytes = [ 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ];
                }
                else // FIXME: This *assumes* that the computer must be 32-bit!
                {
                    ubyte[] lengthBytes = [ 0x00u, 0x00u, 0x00u, 0x00u ];
                }
                
                version (LittleEndian)
                {
                    for (ubyte i = (bytes[1] & 0x7Fu); i > 0u; i--)
                    {
                        lengthBytes[i] = bytes[2+i];
                    }
                }
                version (BigEndian)
                {
                    for (ubyte i = 0x00u; i < (bytes[1] & 0x7Fu); i++)
                    {
                        lengthBytes[i] = bytes[2+i];
                    }
                }

                size_t length = *cast(size_t *) lengthBytes.ptr;
                this.value = bytes[2 .. 3+length];
            }
            else // Indefinite
            {
                // immutable ptrdiff_t indexOfEndOfContent = bytes.indexOf([ 0x00u, 0x00u ]);
                
                size_t indexOfEndOfContent = 0u;
                for (size_t i = 2u; i < bytes.length-1; i++)
                {
                    if ((bytes[i] == 0x00u) && (bytes[i+1] == 0x00))
                        indexOfEndOfContent = i;
                }

                if (indexOfEndOfContent == 0u)
                    throw new ASN1ValueTooSmallException
                    ("No end-of-content word [0x00,0x00] found at the end of indefinite-length encoded BERValue.");

                this.value = bytes[2 .. indexOfEndOfContent];
            }
        }
        else // Definite Short
        {
            ubyte length = (bytes[1] & 0x7Fu);

            if (length > (bytes.length-2))
                throw new ASN1ValueTooSmallException
                ("BER-encoded value terminated prematurely.");

            this.value = bytes[2 .. 2+length].dup;
            bytes = bytes[2+length .. $];
        }
    }

    /**
        This differs from $(D_INLINECODE this.value) in that 
        $(D_INLINECODE this.value) only returns the value octets, whereas
        $(D_INLINECODE this.toBytes) returns the type tag, length tag / octets,
        and the value octets, all concatenated.

        This is the exact same as $(D_INLINECODE this.opCast!(ubyte[])()).

        Returns: type tag, length tag, and value, all concatenated as a ubyte array.
    */
    public @property @system
    ubyte[] toBytes()
    {
        ubyte[] lengthOctets = [ 0x00u ];
        switch (this.lengthEncodingPreference)
        {
            case (LengthEncodingPreference.definite):
            {
                if (this.length < 127u)
                {
                    lengthOctets = [ cast(ubyte) this.length ];    
                }
                else
                {
                    ulong length = cast(ulong) this.value.length;
                    version (BigEndian)
                    {
                        lengthOctets = [ cast(ubyte) 0x88u ] ~ cast(ubyte[]) *cast(ubyte[8] *) &length;
                    }
                    else version (LittleEndian)
                    {
                        // REVIEW: You could use better variable names here.
                        ubyte[] lengthBytes = cast(ubyte[]) *cast(ubyte[8] *) &length;
                        reverse(lengthBytes);
                        lengthOctets = [ cast(ubyte) 0x88u ] ~ lengthBytes;
                    }
                    else
                    {
                        static assert(0, "Could not determine endianness. Cannot compile.");
                    }
                }
                break;
            }
            case (LengthEncodingPreference.indefinite):
            {
                lengthOctets = [ 0x80u ];
                break;
            }
            default:
            {
                assert(0, "Invalid LengthEncodingPreference encountered!");
            }
        }
        return (
            [ this.type ] ~ 
            lengthOctets ~ 
            this.value ~ 
            (this.lengthEncodingPreference == LengthEncodingPreference.indefinite ? cast(ubyte[]) [ 0x00u, 0x00u ] : cast(ubyte[]) [])
        );
    }

    /**
        This differs from $(D_INLINECODE this.value) in that 
        $(D_INLINECODE this.value) only returns the value octets, whereas
        $(D_INLINECODE this.toBytes) returns the type tag, length tag / octets,
        and the value octets, all concatenated.

        This is the exact same as $(D_INLINECODE this.toBytes()).

        Returns: type tag, length tag, and value, all concatenated as a ubyte array.
    */
    public @system nothrow
    ubyte[] opCast(T = ubyte[])()
    {
        ubyte[] lengthOctets = [ 0x00u ];
        switch (this.lengthEncodingPreference)
        {
            case (LengthEncodingPreference.definite):
            {
                if (this.length < 127u)
                {
                    lengthOctets = [ cast(ubyte) this.length ];    
                }
                else
                {
                    ulong length = cast(ulong) this.value.length;
                    version (BigEndian)
                    {
                        lengthOctets = [ cast(ubyte) 0x88u ] ~ cast(ubyte[]) *cast(ubyte[8] *) &length;
                    }
                    else version (LittleEndian)
                    {
                        // REVIEW: You could use better variable names here.
                        ubyte[] lengthBytes = cast(ubyte[]) *cast(ubyte[8] *) &length;
                        reverse(lengthBytes);
                        lengthOctets = [ cast(ubyte) 0x88u ] ~ lengthBytes;
                    }
                    else
                    {
                        static assert(0, "Could not determine endianness. Cannot compile.");
                    }
                }
                break;
            }
            case (LengthEncodingPreference.indefinite):
            {
                lengthOctets = [ 0x80u ];
                break;
            }
            default:
            {
                assert(0, "Invalid lengthEncodingPreference encountered!");
            }
        }
        return (
            [ this.type ] ~ 
            lengthOctets ~ 
            this.value ~ 
            (this.lengthEncodingPreference == LengthEncodingPreference.indefinite ? cast(ubyte[]) [ 0x00u, 0x00u ] : cast(ubyte[]) [])
        );
    }

}

/*
    Tests of all types using definite-short encoding.
*/
@system
unittest
{
    // Test data
    ubyte[] dataEndOfContent = [ 0x00u, 0x00u ];
    ubyte[] dataBoolean = [ 0x01u, 0x01u, 0xFFu ];
    ubyte[] dataInteger = [ 0x02u, 0x08u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0xFFu ];
    ubyte[] dataBitString = [ 0x03u, 0x03u, 0x02u, 0xF0u, 0xF0u ];
    ubyte[] dataOctetString = [ 0x04u, 0x04u, 0xFF, 0x00u, 0x88u, 0x14u ];
    ubyte[] dataNull = [ 0x05u, 0x00u ];
    ubyte[] dataOID = [ 0x06u, 0x04u, 0x2Bu, 0x06u, 0x04u, 0x01u ];
    ubyte[] dataOD = [ 0x07u, 0x05u, 'H', 'N', 'E', 'L', 'O' ];
    ubyte[] dataExternal = [ 
        0x08u, 0x1Cu, 0x80u, 0x0Au, 0x81u, 0x08u, 0x00u, 0x00u, 
        0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x1Bu, 0x81u, 0x08u, 
        0x65u, 0x78u, 0x74u, 0x65u, 0x72u, 0x6Eu, 0x61u, 0x6Cu, 
        0x82u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u ];
    ubyte[] dataReal = [ 0x09u, 0x03u, 0x80u, 0xFBu, 0x05u ]; // 0.15625 (From StackOverflow question)
    ubyte[] dataEnum = [ 0x0Au, 0x08u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0xFFu ];
    ubyte[] dataEmbeddedPDV = [ 
        0x0Bu, 0x1Cu, 0x80u, 0x0Au, 0x82u, 0x08u, 0x00u, 0x00u, 
        0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x1Bu, 0x81u, 0x08u, 
        0x41u, 0x41u, 0x41u, 0x41u, 0x42u, 0x42u, 0x42u, 0x42u, 
        0x82u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u ];
    ubyte[] dataUTF8 = [ 0x0Cu, 0x05u, 'H', 'E', 'N', 'L', 'O' ];
    ubyte[] dataROID = [ 0x0Du, 0x03u, 0x06u, 0x04u, 0x01u ];
    // sequence
    // set
    ubyte[] dataNumeric = [ 0x12u, 0x07u, '8', '6', '7', '5', '3', '0', '9' ];
    ubyte[] dataPrintable = [ 0x13u, 0x06u, '8', '6', ' ', 'b', 'f', '8' ];
    ubyte[] dataTeletex = [ 0x14u, 0x06u, 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ];
    ubyte[] dataVideotex = [ 0x15u, 0x06u, 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ];
    ubyte[] dataIA5 = [ 0x16u, 0x08u, 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S' ];
    ubyte[] dataUTC = [ 0x17u, 0x0Cu, '1', '7', '0', '8', '3', '1', '1', '3', '4', '5', '0', '0' ];
    ubyte[] dataGT = [ 0x18u, 0x0Eu, '2', '0', '1', '7', '0', '8', '3', '1', '1', '3', '4', '5', '0', '0' ];
    ubyte[] dataGraphic = [ 0x19u, 0x0Bu, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    ubyte[] dataVisible = [ 0x1Au, 0x0Bu, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    ubyte[] dataGeneral = [ 0x1Bu, 0x0Bu, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    ubyte[] dataUniversal = [ 
        0x1Cu, 0x10u, 
        0x00u, 0x00u, 0x00u, 0x61u, 
        0x00u, 0x00u, 0x00u, 0x62u, 
        0x00u, 0x00u, 0x00u, 0x63u, 
        0x00u, 0x00u, 0x00u, 0x64u 
    ]; // Big-endian "abcd"
    ubyte[] dataCharacter = [ 
        0x1Du, 0x13u, 0x80u, 0x0Au, 0x82u, 0x08u, 0x00u, 0x00u, 
        0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x3Fu, 0x81u, 0x05u, 
        0x48u, 0x45u, 0x4Eu, 0x4Cu, 0x4Fu ];
    ubyte[] dataBMP = [ 0x1Eu, 0x08u, 0x00u, 0x61u, 0x00u, 0x62u, 0x00u, 0x63u, 0x00u, 0x64u ]; // Big-endian "abcd"

    // Combine it all
    ubyte[] data = 
        dataEndOfContent ~
        dataBoolean ~
        dataInteger ~
        dataBitString ~
        dataOctetString ~
        dataNull ~
        dataOID ~
        dataOD ~
        dataExternal ~ 
        dataReal ~
        dataEnum ~
        dataEmbeddedPDV ~
        dataUTF8 ~
        dataROID ~
        dataNumeric ~
        dataPrintable ~
        dataTeletex ~
        dataVideotex ~
        dataIA5 ~
        dataUTC ~
        dataGT ~
        dataGraphic ~
        dataVisible ~ 
        dataGeneral ~
        dataUniversal ~
        dataCharacter ~
        dataBMP;

    BERValue[] result;
    while (data.length > 0)
        result ~= new BERValue(data);

    // Ensure use of accessors does not mutate state.
    assert(result[1].boolean == result[1].boolean);
    assert(result[2].integer!long == result[2].integer!long);
    assert(cast(size_t[]) result[3].bitString == cast(size_t[]) result[3].bitString); // Not my fault that std.bitmanip.BitArray is fucking stupid.
    assert(result[4].octetString == result[4].octetString);
    // nill
    assert(result[6].objectIdentifier.numericArray == result[6].objectIdentifier.numericArray);
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert(result[8].external == result[8].external);
    assert(result[9].realType!float == result[9].realType!float);
    assert(result[10].enumerated!long == result[10].enumerated!long);
    assert(result[11].embeddedPresentationDataValue == result[11].embeddedPresentationDataValue);
    assert(result[12].utf8String == result[12].utf8String);
    assert(result[13].relativeObjectIdentifier.numericArray == result[13].relativeObjectIdentifier.numericArray);
    assert(result[14].numericString == result[14].numericString);
    assert(result[15].printableString == result[15].printableString);
    assert(result[16].teletexString == result[16].teletexString);
    assert(result[17].videotexString == result[17].videotexString);
    assert(result[18].ia5String == result[18].ia5String);
    assert(result[19].utcTime == result[19].utcTime);
    assert(result[20].generalizedTime == result[20].generalizedTime);
    assert(result[21].graphicString == result[21].graphicString);
    assert(result[22].visibleString == result[22].visibleString);
    assert(result[23].generalString == result[23].generalString);
    assert(result[24].universalString == result[24].universalString);
    assert(result[25].characterString == result[25].characterString);
    assert(result[26].bmpString == result[26].bmpString);

    // Pre-processing
    External x = result[8].external;
    EmbeddedPDV m = result[11].embeddedPresentationDataValue;
    CharacterString c = result[25].characterString;

    // Ensure accessors decode the data correctly.
    assert(result[1].boolean == true);
    assert(result[2].integer!long == 255L);
    // assert(cast(void[]) result[3].bitString == cast(void[]) BitArray([0xF0u, 0xF0u], 14));
    // NOTE: I think std.bitmanip.BitArray.opCast(void[]) is broken...
    assert(result[4].octetString == [ 0xFFu, 0x00u, 0x88u, 0x14u ]);
    assert(result[6].objectIdentifier.numericArray == (new OID(0x01u, 0x03u, 0x06u, 0x04u, 0x01u)).numericArray);
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert((x.identification.presentationContextID == 27L) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[9].realType!float == 0.15625);
    assert(result[9].realType!double == 0.15625);
    assert(result[10].enumerated!long == 255L);
    assert((x.identification.presentationContextID == 27L) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[12].utf8String == "HENLO");
    assert(result[13].relativeObjectIdentifier.numericArray == (new ROID(0x06u, 0x04u, 0x01u)).numericArray);
    assert(result[14].numericString == "8675309");
    assert(result[15].printableString ==  "86 bf8");
    assert(result[16].teletexString == [ 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ]);
    assert(result[17].videotexString == [ 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ]);
    assert(result[18].ia5String == "BORTHERS");
    assert(result[19].utcTime == DateTime(2017, 8, 31, 13, 45));
    assert(result[20].generalizedTime == DateTime(2017, 8, 31, 13, 45));
    assert(result[21].graphicString == "PowerThirst");
    assert(result[22].visibleString == "PowerThirst");
    assert(result[23].generalString == "PowerThirst");
    assert(result[24].universalString == "abcd"d);
    assert((c.identification.presentationContextID == 63L) && (c.stringValue == "HENLO"w));
}