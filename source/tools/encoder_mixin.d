module tools.encoder_mixin;

mixin template Encoder(Element)
{
    import asn1;
    import std.algorithm: map;
    import std.array : array, split;
    import std.conv : ConvException, ConvOverflowException, parse, to;
    import std.datetime.date : DateTime, DateTimeException;
    import std.range: chunks;
    import std.stdio : stderr, stdout;
    import std.string : indexOf;
    import std.utf : UTFException;

    class ArgumentException : Exception
    {
        private import std.exception : basicExceptionCtors;
        mixin basicExceptionCtors;
    }

    void encodeBoolean (Element element, string literal)
    {
        switch (literal)
        {
            case "TRUE" : element.boolean = true; break;
            case "FALSE" : element.boolean = false; break;
            default: stderr.rawWrite("Invalid boolean. Valid options (case insensitive): TRUE, FALSE.\n");
        }
    }

    void encodeInteger (Element element, string literal)
    {
        try
        {
            element.integer!ptrdiff_t = literal.to!ptrdiff_t;
        }
        catch (ConvException e)
        {
            stderr.rawWrite(e.msg);
        }
    }

    void encodeBitString (Element element, string literal)
    {
        bool[] bits;
        bits.length = literal.length;
        for (size_t i = 0u; i < bits.length; i++)
        {
            if (literal[i] == '1') bits[i] = true;
            else if (literal[i] == '0') bits[i] = false;
            else
            {
                stderr.rawWrite("Invalid BIT STRING. BIT STRING only accepts 1s and 0s.\n");
                return;
            }
        }
        element.bitString = bits;
    }

    void encodeOctetString (Element element, string literal)
    {
        // https://stackoverflow.com/questions/23725222/how-do-i-convert-a-bigint-to-a-ubyte/23741556#23741556
        // https://forum.dlang.org/post/welnhsfiqyhchagxilet@forum.dlang.org
        if (literal.length % 2u)
        {
            stderr.rawWrite("Cannot decode an odd number of hexadecimal characters.\n");
            return;
        }
        element.octetString = literal
            .chunks(2)
            .map!(twoDigits => twoDigits.parse!ubyte(16))
            .array();
    }

    alias encodeOID = encodeObjectIdentifier;
    alias encodeObjectID = encodeObjectIdentifier;
    void encodeObjectIdentifier (Element element, string literal)
    {
        try
        {
            element.objectIdentifier = new ObjectIdentifier(literal);
        }
        catch (OIDException e)
        {
            stderr.rawWrite(e.msg);
        }
    }

    alias encodeOD = encodeObjectDescriptor;
    void encodeObjectDescriptor (Element element, string literal)
    {
        try
        {
            element.objectDescriptor = literal;
        }
        catch (ASN1ValueException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    void encodeReal (Element element, string literal)
    {
        try
        {
            element.realNumber!real = literal.to!real;
        }
        catch (ConvException e)
        {
            stderr.rawWrite(e.msg);
        }
    }

    void encodeEnumerated (Element element, string literal)
    {
        try
        {
            element.enumerated!long = literal.to!long;
        }
        catch (ConvException e)
        {
            stderr.rawWrite(e.msg);
        }
    }

    alias encodeUTF8String = encodeUnicodeTransformationFormat8String;
    void encodeUnicodeTransformationFormat8String (Element element, string literal)
    {
        try
        {
            element.utf8String = literal;
        }
        catch (UTFException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    alias encodeROID = encodeRelativeObjectIdentifier;
    alias encodeRelativeOID = encodeRelativeObjectIdentifier;
    alias encodeRelativeObjectID = encodeRelativeObjectIdentifier;
    void encodeRelativeObjectIdentifier (Element element, string literal)
    {
        import std.array : split;
        string[] segments = literal.split(".");
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
    }

    void encodeNumericString (Element element, string literal)
    {
        try
        {
            element.numericString = literal;
        }
        catch (ASN1ValueException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    void encodePrintableString (Element element, string literal)
    {
        try
        {
            element.printableString = literal;
        }
        catch (ASN1ValueException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    alias encodeT61String = encodeTeletexString;
    void encodeTeletexString (Element element, string literal)
    {
        // https://stackoverflow.com/questions/23725222/how-do-i-convert-a-bigint-to-a-ubyte/23741556#23741556
        // https://forum.dlang.org/post/welnhsfiqyhchagxilet@forum.dlang.org
        if (literal.length % 2u)
        {
            stderr.rawWrite("Cannot decode an odd number of hexadecimal characters.\n");
            return;
        }
        element.teletexString = literal
            .chunks(2)
            .map!(twoDigits => twoDigits.parse!ubyte(16))
            .array();
    }

    void encodeVideotexString (Element element, string literal)
    {
        // https://stackoverflow.com/questions/23725222/how-do-i-convert-a-bigint-to-a-ubyte/23741556#23741556
        // https://forum.dlang.org/post/welnhsfiqyhchagxilet@forum.dlang.org
        if (literal.length % 2u)
        {
            stderr.rawWrite("Cannot decode an odd number of hexadecimal characters.\n");
            return;
        }
        element.videotexString = literal
            .chunks(2)
            .map!(twoDigits => twoDigits.parse!ubyte(16))
            .array();
    }

    alias encodeIA5String = encodeInternationalAlphabet5String;
    void encodeInternationalAlphabet5String (Element element, string literal)
    {
        try
        {
            element.ia5String = literal;
        }
        catch (ASN1ValueException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    alias encodeUTCTime = encodeCoordinatedUniversalTime;
    void encodeCoordinatedUniversalTime (Element element, string literal)
    {
        try
        {
            element.utcTime = DateTime.fromISOString(literal);
        }
        catch (DateTimeException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    void encodeGeneralizedTime (Element element, string literal)
    {
        try
        {
            element.generalizedTime = DateTime.fromISOString(literal);
        }
        catch (DateTimeException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    void encodeGraphicString (Element element, string literal)
    {
        try
        {
            element.graphicString = literal;
        }
        catch (ASN1ValueException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    void encodeVisibleString (Element element, string literal)
    {
        try
        {
            element.visibleString = literal;
        }
        catch (ASN1ValueException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    void encodeGeneralString (Element element, string literal)
    {
        try
        {
            element.generalString = literal;
        }
        catch (ASN1ValueException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    void encodeUniversalString (Element element, string literal)
    {
        try
        {
            element.universalString = cast(dstring) literal;
        }
        catch (ASN1ValueException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    alias encodeBMPString = encodeBasicMultilingualPlaneString;
    void encodeBasicMultilingualPlaneString (Element element, string literal)
    {
        try
        {
            element.bmpString = cast(wstring) literal;
        }
        catch (ASN1ValueException e)
        {
            stderr.rawWrite(e.msg ~ "\n");
        }
    }

    ubyte[] encode (string arg)
    {
        if (arg.length < 11u)
        {
            stderr.rawWrite("Argument too short.\n");
            return [];
        }

        if (arg[0] != '[')
        {
            stderr.rawWrite("Each argument must start with a '['.\n");
            return [];
        }

        ptrdiff_t indexOfDefinition = arg.indexOf("]::=");

        if (indexOfDefinition == -1)
        {
            stderr.rawWrite("Each argument must be of the form [??#]::=???:...\n");
            return [];
        }

        Element element = new Element();
        switch (arg[1])
        {
            case ('U'): element.tagClass = ASN1TagClass.universal; break;
            case ('A'): element.tagClass = ASN1TagClass.application; break;
            case ('C'): element.tagClass = ASN1TagClass.contextSpecific; break;
            case ('P'): element.tagClass = ASN1TagClass.privatelyDefined; break;
            default: stderr.rawWrite("Invalid tag class selection. Must be U, A, C, or P.\n");
        }
        switch (arg[2])
        {
            case ('P'): element.construction = ASN1Construction.primitive; break;
            case ('C'): element.construction = ASN1Construction.constructed; break;
            default: stderr.rawWrite("Invalid construction selection. Must be P or C.\n");
        }

        {
            string number = arg[3 .. indexOfDefinition];
            element.tagNumber = number.to!size_t;
        }

        {
            string valueVector = arg[(indexOfDefinition + 4u) .. $];
            ptrdiff_t indexOfColon = valueVector.indexOf(":");
            if (indexOfColon == -1)
            {
                stderr.rawWrite("Invalid value. Must provide a encoding method.\n");
                return [];
            }

            switch (valueVector[0 .. indexOfColon])
            {
                case("eoc"): break;
                case("bool"): encodeBoolean(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("int"): encodeInteger(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("bit"): encodeBitString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("oct"): encodeOctetString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("null"): break;
                case("oid"): encodeOID(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("od"): encodeObjectDescriptor(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("real"): encodeReal(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("enum"): encodeEnumerated(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("utf8"): encodeUTF8String(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("roid"): encodeRelativeOID(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("numeric"): encodeNumericString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("printable"): encodePrintableString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("teletex"): encodeTeletexString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("videotex"): encodeVideotexString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("ia5"): encodeIA5String(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("utc"): encodeUTCTime(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("time"): encodeGeneralizedTime(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("graphic"): encodeGraphicString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("visible"): encodeVisibleString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("general"): encodeGeneralString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("universal"): encodeUniversalString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                case("bmp"): encodeBMPString(element, valueVector[(indexOfColon + 1u) .. $]); break;
                default: stderr.rawWrite("Invalid encoding method: '" ~ valueVector[0 .. indexOfColon] ~ "' \n");
            }
        }

        return element.toBytes;
    }

    int main(string[] args)
    {
        ubyte[] encodedData;

        if (args.length < 2u)
        {
            stderr.rawWrite("Too few arguments.\n");
            return 1;
        }

        foreach (arg; args[1 .. $])
        {
            encodedData ~= encode(arg);
        }

        stdout.rawWrite(encodedData);
        return 0;
    }
}