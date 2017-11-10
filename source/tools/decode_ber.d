/**
    Decodes DER-encoded data from either standard input, or a file, if the file
    is specified on the command line.
*/
import asn1;
import codecs.ber;
import core.stdc.stdlib : getenv;
import std.conv : ConvException;
import std.file : exists, FileException, isFile, read;
import std.getopt;
import std.path : isValidFilename, isValidPath;
import std.stdio : write, writeln, writefln, stdin;
import std.string : fromStringz;
import std.utf : UTFException;

bool colorOutput = false;
string filePath = "";
bool verbose = false;
ubyte[] data = [];

int main(string[] args)
{

    enum ReturnValue : int
    {
        success = 0,
        errorParsingCommandLineArguments = 1,
        invalidFilePathOrFileName = 2,
        fileNotFound = 3,
        pathIsNotFile = 4,
        readPermissionDenied = 5,
        elementTerminatedPrematurely = 6,
        invalidEncodedValue = 7,
        unexpectedException = int.max
    }

    // REVIEW: Will this work on a Windows host?
    // Retrieve and Parse Environment Variables
    string colorOutputEnvVar = cast(string) fromStringz(getenv("COLOR"));
    colorOutput = (colorOutputEnvVar == "true" ? true : false);

    /*
        Option ideas:
        -t  TCP port
        -u  UDP port
    */
    // NOTE: '-h' and '--help' are reserved.
    try
    {
        GetoptResult getOptResult = getopt(
            args,
            std.getopt.config.caseInsensitive,
            std.getopt.config.bundling,
            "c|color", &colorOutput,
            "f|file", &filePath,
            "v|verbose", &verbose
        );

        if (getOptResult.helpWanted)
        {
            defaultGetoptPrinter(
                "Usage syntax:\n\tdecode-der [options ...] -f {file}",
                getOptResult.options);
        }
    }
    catch (ConvException ce)
    {
        writeln("Command line arguments could not be parsed.");
        return ReturnValue.errorParsingCommandLineArguments;
    }
    catch (GetOptException goe)
    {
        writeln(goe.msg);
        return ReturnValue.errorParsingCommandLineArguments;
    }

    if (filePath != "")
    {
        // This throws when the file contains '@', which is valid on Unix-like systems.
        // if (!filePath.isValidFilename())
        // {
        //     writeln("Invalid file name.");
        //     return ReturnValue.invalidFilePathOrFileName;
        // }

        if (!filePath.isValidPath())
        {
            writeln("Invalid file path.");
            return ReturnValue.invalidFilePathOrFileName;
        }

        if (!exists(filePath))
        {
            writeln("File not found.");
            return ReturnValue.fileNotFound;
        }

        /* NOTE:
            Though isFile() can throw a FileException if the file does not 
            exist, we assume that the file does exist at this point, since
            we tested it with exist() in the line above this. However, if
            by some freak accident, the file disappears between these two
            steps, the line below will throw a FileException.
        */
        if (!filePath.isFile())
        {
            writeln("Path argument does not point to a file, but a directory or socket or something else.");
            return ReturnValue.pathIsNotFile;
        }

        try
        {
            data = cast(ubyte[]) read(filePath);
        }
        catch (FileException fe)
        {
            writeln("File cannot be opened or read.");
            return ReturnValue.readPermissionDenied;
        }

    }
    else
    {
        stdin.rawRead(data);
    }

    BERElement[] tops;
    while (data.length > 0)
        tops ~= new BERElement(data);

    foreach (top; tops)
    {
        try
        {
            display(top, 0u);
        }
        catch (ASN1ValueTooSmallException e)
        {
            writeln(e.msg);
            return ReturnValue.elementTerminatedPrematurely;
        }
        catch (ASN1Exception e)
        {
            writeln(e.msg);
            return ReturnValue.invalidEncodedValue;
        }
        catch (Exception e)
        {
            writeln(e.msg);
            return ReturnValue.unexpectedException;
        }
    }

    return ReturnValue.success;
}

void display (BERElement element, ubyte indentation)
{
    string typeClassString = "";
    bool universal = false;
    switch (element.typeClass)
    {
        case (ASN1TagClass.universal):
        {
            typeClassString = "UNIV";
            universal = true;
            break;
        }
        case (ASN1TagClass.application):
        {
            typeClassString = "APPL";
            break;
        }
        case (ASN1TagClass.contextSpecific):
        {
            typeClassString = "CTXT";
            break;
        }
        case (ASN1TagClass.privatelyDefined):
        {
            typeClassString = "PRIV";
            break;
        }
        default:
        {
            assert(0, "Impossible typeClass encountered!");
        }
    }

    char[] indents;
    indents.length = indentation;
    indents[0 .. $] = ' ';

    if (element.typeConstruction == ASN1Construction.primitive)
    {
        if (universal)
        {
            writefln("%s[ %s %d ] : %s", cast(string) indents, typeClassString, element.typeNumber!ubyte, stringifyUniversalValue(element));
        }
        else
        {
            writefln("%s[ %s %d ] : %(%02X %)", cast(string) indents, typeClassString, element.typeNumber!ubyte, element.value);
        }
    }
    else
    {
        writefln("%s[ %s %d ] :", cast(string) indents, typeClassString, element.typeNumber!ubyte);
        indentation += 4;

        ubyte[] value = element.value.dup;
        BERElement[] subs;
        size_t i = 0u;
        while (i < value.length)
            subs ~= new BERElement(i, value);

        foreach (sub; subs)
        {
            display(new BERElement(element.value), indentation); 
        }
    }
    indentation -= 4;
}

string stringifyUniversalValue (BERElement element)
{
    import std.conv : text;
    switch (element.typeNumber!ubyte)
    {
        case (0x00u):
        {
            return "END OF CONTENT";
        }
        case (0x01u):
        {
            return (element.boolean ? "TRUE" : "FALSE");
        }
        case (0x02u):
        {
            return text(element.integer!long);
        }
        case (0x03u):
        {
            return "BIT STRING";
        }
        case (0x04u):
        {
            return text(element.octetString);
        }
        case (0x05u):
        {
            return "NULL";
        }
        case (0x06u):
        {
            return element.objectIdentifier.toString();
        }
        case (0x07u):
        {
            return element.objectDescriptor;
        }
        case (0x08u):
        {
            // This should never be executed.
            return "EXTERNAL";
        }
        case (0x09u):
        {
            return text(element.realType!double);
        }
        case (0x0Au):
        {
            return text(element.enumerated!long);
        }
        case (0x0Bu):
        {
            // This should never be executed.
            return "EMBEDDED PDV";
        }
        case (0x0Cu):
        {
            return element.utf8String;
        }
        case (0x0Du):
        {
            return ("RELATIVE OID: " ~ text(element.value));
        }
        case (0x0E):
        {
            return "!!! INVALID TYPE : RESERVED 14 !!!";
        }
        case (0x0F):
        {
            return "!!! INVALID TYPE : RESERVED 15 !!!";
        }
        case (0x10u):
        {
            // This should never be executed.
            return "SEQUENCE";
        }
        case (0x11u):
        {
            // This should never be executed.
            return "SET";
        }
        case (0x12u):
        {
            return element.numericString;
        }
        case (0x13u):
        {
            return element.printableString;
        }
        case (0x14u):
        {
            return text(element.teletexString);
        }
        case (0x15u):
        {
            return text(element.videotexString);
        }
        case (0x16u):
        {
            return element.ia5String;
        }
        case (0x17u):
        {
            return element.utcTime.toISOString();
        }
        case (0x18u):
        {
            return element.generalizedTime.toISOString();
        }
        case (0x19u):
        {
            return element.graphicString;
        }
        case (0x1Au):
        {
            return element.visibleString;
        }
        case (0x1Bu):
        {
            return element.generalString;
        }
        case (0x1Cu):
        {
            return "[ UniversalString that cannot be displayed. ]";
        }
        case (0x1Du):
        {
            // This should never be executed.
            return "CharacterString";
        }
        case (0x1Eu):
        {
            return "[ BMPString that cannot be displayed. ]";
        }
        case (0x1Fu):
        {
            return "!!! INVALID TYPE : UNDEFINED 31 !!!";
        }
        default:
        {
            return "!!! INVALID TYPE : TypeNumber somehow exceeded 31 !!!";
        }
    }
}