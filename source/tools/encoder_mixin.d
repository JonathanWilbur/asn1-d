module tools.encoder_mixin;

mixin template Encoder(Element)
{
    import asn1;
    import cli;
    import std.ascii : toLower;
    import std.conv : ConvException, ConvOverflowException, to;
    import std.datetime.date : DateTime, DateTimeException;
    import std.file : read;
    import std.math : isNaN;
    import std.stdio : stderr, stdout;
    import std.utf : UTFException;

    // TODO: REAL format options
    // TODO: Context-Switching Type options?
    // TODO: Number option

    ASN1TagClass tagClass = ASN1TagClass.universal;
    ASN1Construction construction = ASN1Construction.primitive;
    uint tagNumber = uint.max;
    ubyte[] encodedData;

    void setTagClass (string value)
    {
        switch (value[0].toLower)
        {
            case ('u'):
            {
                tagClass = ASN1TagClass.universal;
                break;
            }
            case ('a'):
            {
                tagClass = ASN1TagClass.application;
                break;
            }
            case ('c'):
            {
                tagClass = ASN1TagClass.contextSpecific;
                break;
            }
            case ('p'):
            {
                tagClass = ASN1TagClass.privatelyDefined;
                break;
            }
            default:
            {
                stderr.rawWrite("Supplied tag class '" ~ value ~ "' could not be resolved to one of: universal, application, context, private");
                return;
            }
        }
    }

    void setTagNumber (string value)
    {
        try
        {
            tagNumber = value.to!uint;
        }
        catch (ConvOverflowException e)
        {
            stderr.rawWrite(e.msg);
            return;
        }
        catch (ConvException e)
        {
            stderr.rawWrite(e.msg);
            return;
        }
    }

    alias encodeEOC = encodeEndOfContent;
    void encodeEndOfContent (string option)
    {
        Element element = new Element();
        element.typeNumber = ((tagNumber == uint.max) ? 0u : tagNumber);
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        encodedData ~= element.toBytes;
    }

    void encodeBoolean (string value)
    {
        import std.algorithm.iteration : each;
        value.each!((ref a) => a.toLower);
        Element element = new Element();
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

    void encodeInteger (string value)
    {
        Element element = new Element();
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

    void encodeBitString (string value)
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
        Element element = new Element();
        element.typeNumber = 3u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        element.bitString = bits;
        encodedData ~= element.toBytes;
    }

    void encodeOctetString (string value)
    {
        Element element = new Element();
        element.typeNumber = 4u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        element.octetString = getBinaryInput(value);
        encodedData ~= element.toBytes;
    }

    void encodeNull (string option)
    {
        Element element = new Element();
        element.typeNumber = 5u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        encodedData ~= element.toBytes;
    }

    alias encodeOID = encodeObjectIdentifier;
    alias encodeObjectID = encodeObjectIdentifier;
    void encodeObjectIdentifier (string value)
    {
        Element element = new Element();
        element.typeNumber = 6u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        try
        {
            element.objectIdentifier = new ObjectIdentifier(value);
        }
        catch (OIDException e)
        {
            stderr.rawWrite(e.msg);
        }
        encodedData ~= element.toBytes;
    }

    alias encodeOD = encodeObjectDescriptor;
    void encodeObjectDescriptor (string value)
    {
        Element element = new Element();
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

    void encodeExternal (string value)
    {
        Element element = new Element();
        element.typeNumber = 8u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        element.value = getBinaryInput(value);
        encodedData ~= element.toBytes;
    }

    void encodeReal (string value)
    {
        Element element = new Element();
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

    void encodeEnumerated (string value)
    {
        Element element = new Element();
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
    void encodeEmbeddedPresentationDataValue (string value)
    {
        Element element = new Element();
        element.typeNumber = 11u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        element.value = getBinaryInput(value);
        encodedData ~= element.toBytes;
    }

    alias encodeUTF8String = encodeUnicodeTransformationFormat8String;
    void encodeUnicodeTransformationFormat8String (string value)
    {
        Element element = new Element();
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
    void encodeRelativeObjectIdentifier (string value)
    {
        import std.array : split;
        Element element = new Element();
        element.typeNumber = 13u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;

        string[] segments = value.split(".");
        uint[] numbers;
        numbers.length = segments.length;

        for (size_t i = 0u; i < segments.length; i++)
        {
            numbers[i] = segments[i].to!uint;
        }

        Appender!(OIDNode[]) nodes = appender!(OIDNode[]);
        foreach (number; numbers)
        {
            nodes.put(OIDNode(number));
        }

        element.relativeObjectIdentifier = nodes.data;
        encodedData ~= element.toBytes;
    }

    void encodeSequence (string value)
    {
        Element element = new Element();
        element.typeNumber = 16u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        element.value = getBinaryInput(value);
        encodedData ~= element.toBytes;
    }

    void encodeSet (string value)
    {
        Element element = new Element();
        element.typeNumber = 17u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        element.value = getBinaryInput(value);
        encodedData ~= element.toBytes;
    }

    void encodeNumericString (string value)
    {
        Element element = new Element();
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

    void encodePrintableString (string value)
    {
        Element element = new Element();
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
    void encodeTeletexString (string value)
    {
        Element element = new Element();
        element.typeNumber = 20u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        element.value = getBinaryInput(value);
        encodedData ~= element.toBytes;
    }

    void encodeVideotexString (string value)
    {
        Element element = new Element();
        element.typeNumber = 21u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        element.value = getBinaryInput(value);
        encodedData ~= element.toBytes;
    }

    alias encodeIA5String = encodeInternationalAlphabet5String;
    void encodeInternationalAlphabet5String (string value)
    {
        Element element = new Element();
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
    void encodeCoordinatedUniversalTime (string value)
    {
        Element element = new Element();
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

    void encodeGeneralizedTime (string value)
    {
        Element element = new Element();
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

    void encodeGraphicString (string value)
    {
        Element element = new Element();
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

    void encodeVisibleString (string value)
    {
        Element element = new Element();
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

    void encodeGeneralString (string value)
    {
        Element element = new Element();
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

    void encodeUniversalString (string value)
    {
        Element element = new Element();
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

    void encodeCharacterString (string value)
    {
        Element element = new Element();
        element.typeNumber = 29u;
        element.typeClass = tagClass;
        element.typeConstruction = construction;
        element.value = getBinaryInput(value);
        encodedData ~= element.toBytes;
    }

    alias encodeBMPString = encodeBasicMultilingualPlaneString;
    void encodeBasicMultilingualPlaneString (string value)
    {
        Element element = new Element();
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

        try
        {
            (new GNUCLIParser(
                CLIOption("class", &setTagClass),
                CLIOption("tag-class", &setTagClass),
                CLIOption("number", &setTagNumber),
                CLIOption("tag-number", &setTagNumber),
                CLIOption("1", &encodeBitString),
                CLIOption("bit", &encodeBitString),
                CLIOption("bit-string", &encodeBitString),
                CLIOption("8", &encodeOctetString),
                CLIOption("oct", &encodeOctetString),
                CLIOption("octet-string", &encodeOctetString),
                CLIOption("b", &encodeBoolean),
                CLIOption("bool", &encodeBoolean),
                CLIOption("boolean", &encodeBoolean),
                CLIOption("B", &encodeBMPString),
                CLIOption("bmp", &encodeBMPString),
                CLIOption("bmp-string", &encodeBMPString),
                CLIOption("C", &encodeCharacterString),
                CLIOption("cs", &encodeCharacterString),
                CLIOption("character-string", &encodeCharacterString),
                CLIOption("d", &encodeObjectDescriptor),
                CLIOption("desc", &encodeObjectDescriptor),
                CLIOption("obj-desc", &encodeObjectDescriptor),
                CLIOption("object-descriptor", &encodeObjectDescriptor),
                CLIOption("e", &encodeEnumerated),
                CLIOption("enum", &encodeEnumerated),
                CLIOption("enumerated", &encodeEnumerated),
                CLIOption("G", &encodeGraphicString),
                CLIOption("graphic", &encodeGraphicString),
                CLIOption("graphic-string", &encodeGraphicString),
                CLIOption("i", &encodeInteger),
                CLIOption("int", &encodeInteger),
                CLIOption("integer", &encodeInteger),
                CLIOption("I", &encodeIA5String),
                CLIOption("ia5", &encodeIA5String),
                CLIOption("ia5-string", &encodeIA5String),
                CLIOption("J", &encodeGeneralString),
                CLIOption("general", &encodeGeneralString),
                CLIOption("general-string", &encodeGeneralString),
                CLIOption("m", &encodeEmbeddedPDV),
                CLIOption("embedded", &encodeEmbeddedPDV),
                CLIOption("pdv", &encodeEmbeddedPDV),
                CLIOption("embedded-pdv", &encodeEmbeddedPDV),
                CLIOption("n", &encodeNull),
                CLIOption("null", &encodeNull),
                CLIOption("N", &encodeNumericString),
                CLIOption("num", &encodeNumericString),
                CLIOption("numeric", &encodeNumericString),
                CLIOption("numeric-string", &encodeNumericString),
                CLIOption("o", &encodeObjectIdentifier),
                CLIOption("oid", &encodeObjectIdentifier),
                CLIOption("object-id", &encodeObjectIdentifier),
                CLIOption("object-identifier", &encodeObjectIdentifier),
                CLIOption("O", &encodeRelativeObjectID),
                CLIOption("roid", &encodeRelativeObjectID),
                CLIOption("relative-oid", &encodeRelativeObjectID),
                CLIOption("relative-object-id", &encodeRelativeObjectID),
                CLIOption("relative-object-identifier", &encodeRelativeObjectID),
                CLIOption("P", &encodePrintableString),
                CLIOption("print", &encodePrintableString),
                CLIOption("printable", &encodePrintableString),
                CLIOption("printable-string", &encodePrintableString),
                CLIOption("q", &encodeTeletexString),
                CLIOption("t61", &encodeTeletexString),
                CLIOption("teletex", &encodeTeletexString),
                CLIOption("teletex-string", &encodeTeletexString),
                CLIOption("Q", &encodeVideotexString),
                CLIOption("videotex", &encodeVideotexString),
                CLIOption("videotex-string", &encodeVideotexString),
                CLIOption("r", &encodeReal),
                CLIOption("real", &encodeReal),
                CLIOption("s", &encodeSequence),
                CLIOption("seq", &encodeSequence),
                CLIOption("sequence", &encodeSequence),
                CLIOption("S", &encodeSet),
                CLIOption("set", &encodeSet),
                CLIOption("t", &encodeUTCTime),
                CLIOption("utc", &encodeUTCTime),
                CLIOption("utc-time", &encodeUTCTime),
                CLIOption("T", &encodeGeneralizedTime),
                CLIOption("time", &encodeGeneralizedTime),
                CLIOption("gen-time", &encodeGeneralizedTime),
                CLIOption("generalizedtime", &encodeGeneralizedTime),
                CLIOption("u", &encodeUTF8String),
                CLIOption("utf8", &encodeUTF8String),
                CLIOption("utf8-string", &encodeUTF8String),
                CLIOption("U", &encodeUniversalString),
                CLIOption("univ", &encodeUniversalString),
                CLIOption("universal", &encodeUniversalString),
                CLIOption("universal-string", &encodeUniversalString),
                CLIOption("V", &encodeVisibleString),
                CLIOption("visible", &encodeVisibleString),
                CLIOption("visible-string", &encodeVisibleString),
                CLIOption("x", &encodeExternal),
                CLIOption("ext", &encodeExternal),
                CLIOption("external", &encodeExternal),
                CLIOption("z", &encodeEndOfContent),
                CLIOption("eoc", &encodeEndOfContent),
                CLIOption("end", &encodeEndOfContent),
                CLIOption("end-of-content", &encodeEndOfContent)
            )).parse(args[1 .. $]);
        }
        catch (CLIException)
        {
            return ReturnValue.errorParsingCommandLineArguments;
        }

        stdout.rawWrite(encodedData);
        return ReturnValue.success;
    }
}