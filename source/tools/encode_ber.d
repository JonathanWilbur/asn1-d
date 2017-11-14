import asn1;
import codecs.ber;
import core.stdc.stdlib : getenv;
import std.conv : ConvException, to;
import std.datetime.date : DateTime, DateTimeException;
import std.file : read;
import std.getopt;
import std.math : isNaN;
import std.stdio : write, writefln, writeln, stderr, stdout;
import std.utf : UTFException;

// TODO: REAL format options
// TODO: Context-Switching Type options?
// TODO: Number option

ASN1TagClass tagClass = ASN1TagClass.universal;
ASN1Construction construction = ASN1Construction.primitive;
ubyte[] encodedData;

alias encodeEOC = encodeEndOfContent;
void encodeEndOfContent (string option)
{
    BERElement element = new BERElement();
    element.typeNumber = 0u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    encodedData ~= element.toBytes;
}

void encodeBoolean (string option, string value)
{
    import std.algorithm.iteration : each;
    import std.ascii : toLower;
    value.each!((ref a) => a.toLower);
    BERElement element = new BERElement();
    element.typeNumber = 1u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    switch (value)
    {
        case "true" : case "t" : case "1" :
        {
            element.boolean = true;
            break;
        }
        case "false" : case "f" : case "0" :
        {
            element.boolean = false;
            break;
        }
        default:
        {
            stderr.rawWrite("Invalid boolean. Valid options (case insensitive): true, t, 1, false, f, 0.\n");
            return;
        }
    }
    encodedData ~= element.toBytes;
}

void encodeInteger (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 2u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.integer!long = value.to!long;
    }
    catch (ConvException e)
    {
        stderr.rawWrite(e.msg);
        return;
    }
    encodedData ~= element.toBytes;
}

void encodeBitString (string option, string value)
{
    bool[] bits;
    bits.length = value.length;
    for (size_t i = 0u; i < bits.length; i++)
    {
        if (value[i] == '1')
        {
            bits[i] = true;
        }
        else if (value[i] == '0')
        {
            bits[i] = false;
        }
        else
        {
            stderr.rawWrite("Invalid BIT STRING. BIT STRING only accepts 1s and 0s.\n");
        }
    }
    BERElement element = new BERElement();
    element.typeNumber = 3u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    element.bitString = bits;
    encodedData ~= element.toBytes;
}

void encodeOctetString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 4u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    element.octetString = getBinaryInput(value);
    encodedData ~= element.toBytes;
}

void encodeNull (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 5u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    encodedData ~= element.toBytes;
}

alias encodeOID = encodeObjectIdentifier;
alias encodeObjectID = encodeObjectIdentifier;
void encodeObjectIdentifier (string option, string value)
{
    // TODO: Create string constructor for OIDs.
}

alias encodeOD = encodeObjectDescriptor;
void encodeObjectDescriptor (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 7u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.objectDescriptor = value;
    }
    catch (ASN1ValueInvalidException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

void encodeExternal (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 8u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    element.value = getBinaryInput(value);
    encodedData ~= element.toBytes;
}

void encodeReal (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 9u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.realType!double = value.to!double;
    }
    catch (ConvException e)
    {
        stderr.rawWrite(e.msg);
        return;
    }
    encodedData ~= element.toBytes;
}

void encodeEnumerated (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 10u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.enumerated!long = value.to!long;
    }
    catch (ConvException e)
    {
        stderr.rawWrite(e.msg);
        return;
    }
    encodedData ~= element.toBytes;
}

alias encodeEmbeddedPDV = encodeEmbeddedPresentationDataValue;
void encodeEmbeddedPresentationDataValue (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 11u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    element.value = getBinaryInput(value);
    encodedData ~= element.toBytes;
}

alias encodeUTF8String = encodeUnicodeTransformationFormat8String;
void encodeUnicodeTransformationFormat8String (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 12u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.utf8String = value;        
    }
    catch (UTFException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

alias encodeROID = encodeRelativeObjectIdentifier;
alias encodeRelativeOID = encodeRelativeObjectIdentifier;
alias encodeRelativeObjectID = encodeRelativeObjectIdentifier;
void encodeRelativeObjectIdentifier (string option, string value)
{

}

void encodeSequence (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 16u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    element.value = getBinaryInput(value);
    encodedData ~= element.toBytes;
}

void encodeSet (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 17u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    element.value = getBinaryInput(value);
    encodedData ~= element.toBytes;
}

void encodeNumericString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 18u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.numericString = value;
    }
    catch (ASN1ValueInvalidException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

void encodePrintableString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 19u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.printableString = value;
    }
    catch (ASN1ValueInvalidException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

alias encodeT61String = encodeTeletexString;
void encodeTeletexString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 20u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    element.value = getBinaryInput(value);
    encodedData ~= element.toBytes;
}

void encodeVideotexString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 21u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    element.value = getBinaryInput(value);
    encodedData ~= element.toBytes;
}

alias encodeIA5String = encodeInternationalAlphabet5String;
void encodeInternationalAlphabet5String (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 22u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.ia5String = value;
    }
    catch (ASN1ValueInvalidException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

alias encodeUTCTime = encodeCoordinatedUniversalTime;
void encodeCoordinatedUniversalTime (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 23u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.utcTime = DateTime.fromISOString(value);
    }
    catch (DateTimeException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

void encodeGeneralizedTime (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 24u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.generalizedTime = DateTime.fromISOString(value);
    }
    catch (DateTimeException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

void encodeGraphicString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 25u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.graphicString = value;
    }
    catch (ASN1ValueInvalidException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

void encodeVisibleString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 26u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.visibleString = value;
    }
    catch (ASN1ValueInvalidException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

void encodeGeneralString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 27u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.generalString = value;
    }
    catch (ASN1ValueInvalidException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

void encodeUniversalString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 28u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.universalString = cast(dstring) value;
    }
    catch (ASN1ValueInvalidException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
        return;
    }
    encodedData ~= element.toBytes;
}

void encodeCharacterString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 29u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    element.value = getBinaryInput(value);
    encodedData ~= element.toBytes;
}

alias encodeBMPString = encodeBasicMultilingualPlaneString;
void encodeBasicMultilingualPlaneString (string option, string value)
{
    BERElement element = new BERElement();
    element.typeNumber = 30u;
    element.typeClass = tagClass;
    element.typeConstruction = construction;
    try
    {
        element.bmpString = cast(wstring) value;
    }
    catch (ASN1ValueInvalidException e)
    {
        stderr.rawWrite(e.msg ~ "\n");
    }
    encodedData ~= element.toBytes;
}

ubyte[] getBinaryInput (string value)
{
    import std.algorithm.iteration : map;
    import std.algorithm.searching : startsWith;
    import std.array : array;
    import std.conv : parse;
    import std.range : chunks;

    if (value.startsWith("hex:"))
    {
        // https://stackoverflow.com/questions/23725222/how-do-i-convert-a-bigint-to-a-ubyte/23741556#23741556
        // https://forum.dlang.org/post/welnhsfiqyhchagxilet@forum.dlang.org
        string hexstr = value[4 .. $];
        if (hexstr.length % 2u)
        {
            stderr.rawWrite("Cannot decode an odd number of hexadecimal characters.\n");
            return [];
        }
        return hexstr
            .chunks(2)
            .map!(twoDigits => twoDigits.parse!ubyte(16))
            .array();
    }
    else if (value.startsWith("base64:"))
    {
        import std.base64 : Base64, Base64Exception;
        auto buffer = new ubyte[Base64.decodeLength(value[7 .. $].length)];
        try
        {
            Base64.decode(value[7 .. $], buffer);
        }
        catch (Base64Exception e)
        {
            stderr.rawWrite("Invalid Base64.\n");
            return [];
        }
        return cast(ubyte[]) buffer;
    }
    else if (value.startsWith("file:"))
    {
        import std.file : exists, FileException, isFile;
        import std.path : isValidPath;  
        string filePath = value[5 .. $];
        if (!filePath.isValidPath())
        {
            stderr.rawWrite("Invalid file path.\n");
            return [];
        }
        if (!exists(filePath))
        {
            stderr.rawWrite("File not found.\n");
            return [];
        }
        if (!filePath.isFile())
        {
            stderr.rawWrite("Selected file system object is not a file.\n");
            return [];
        }
        try
        {
            return (cast(ubyte[]) read(filePath));
        }
        catch (FileException fe)
        {
            stderr.rawWrite("Unable to read file. Check permissions.\n");
            return [];
        }
    }
    else if (value == "stdin")
    {
        // REVIEW: Can this ever throw an exception?
        import std.stdio : stdin;
        ubyte[] ret;
        foreach (ubyte[] buffer; stdin.byChunk(new ubyte[4096]))
        {
            ret ~= buffer;
        }
        return ret;
    }
    else
    {
        stderr.rawWrite("Invalid argument. Use hex:, base64:, file:, or stdin.\n");
        return [];
    }
}

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
    
    // NOTE: '-h' and '--help' are reserved.
    try
    {
        GetoptResult getOptResult = getopt(
            args,
            std.getopt.config.caseSensitive,
            "b|bool|boolean", &encodeBoolean,
            "B|bmp|bmp-string", &encodeBMPString,
            "C|cs|character-string", &encodeCharacterString,
            "d|desc|objdesc|object-descriptor", &encodeObjectDescriptor,
            "e|enum|enumerated", &encodeEnumerated,
            "G|graphic|graphic-string", &encodeGraphicString,
            "i|int|integer", &encodeInteger,
            "I|ia5|ia5-string", &encodeIA5String,
            "J|general|general-string", &encodeGeneralString,
            "m|embedded|pdv|embedded-pdv", &encodeEmbeddedPDV,
            "n|null", &encodeNull,
            "N|num|numeric|numeric-string", &encodeNumericString,
            // "o|oid|object-id|object-identifier", &encodeOID,
            // "O|roid|relative-oid|relative-object-id|relative-object-identifier",
            "P|printable|printable-string", &encodePrintableString,
            "q|t61|ttex|teletex|teletex-string", &encodeTeletexString,
            "Q|vtex|videotex|videotex-string", &encodeVideotexString,
            "r|real", &encodeReal,
            "s|seq|sequence", &encodeSequence,
            "S|set", &encodeSet,
            "t|utc|utc-time", &encodeUTCTime,
            "T|gen-time|generalized-time", &encodeGeneralizedTime,
            "u|utf8|utf8-string", &encodeUTF8String,
            "U|univ|universal-string", &encodeUniversalString,
            "V|visible|visible-string", &encodeVisibleString,
            "x|ext|external", &encodeExternal,
            "z|eoc|end-of-content", &encodeEndOfContent,
            "1|bit|bit-string", &encodeBitString,
            "8|oct|octet-string", &encodeOctetString,
            "class|tag-class", &tagClass,
            "construction", &construction
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

    stdout.rawWrite(encodedData);
    return ReturnValue.success;
}