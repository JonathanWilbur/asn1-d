module asn1.tools.decoder_mixin;

mixin template Decoder(Element)
{
    import asn1.constants;
    import std.conv : ConvException;
    import std.stdio : write, writeln, writefln, stdin;
    import std.utf : UTFException;

    int main(string[] args)
    {
        enum ReturnValue : int
        {
            success = 0,
            elementTerminatedPrematurely = 1,
            invalidEncodedValue = 2,
            unexpectedException = int.max
        }

        ubyte[] data = stdin.rawRead!ubyte(new ubyte[500000]);

        if (args.length == 2u && data.length > 0u)
        {
            if (args[1] == "-n")
            {
                if (data[$-1] == '\n')
                {
                    data = data[0 .. $-1];
                    writeln("Removed a trailing LineFeed character from input.");
                }
                else writeln("There was no trailing LineFeed character to remove from input.");
            }
            else if (args[1] == "-r")
            {
                if (data[$-2 .. $] == "\r\n")
                {
                    data = data[0 .. $-2];
                    writeln("Removed a trailing CarriageReturn+LineFeed from input.");
                }
                else writeln("There was no trailing CarriageReturn+LineFeed to remove from input.");
            }
            else writeln("Ignoring unrecognized option or argument: '" ~ args[1] ~"'.");
        }

        Element[] tops;

        try
        {
            while (data.length > 0u)
                tops ~= new Element(data);
        }
        catch (ASN1ValueSizeException e)
        {
            writeln("\n", e.msg, "\n");
            return ReturnValue.elementTerminatedPrematurely;
        }
        catch (ASN1Exception e)
        {
            writeln("\n", e.msg, "\n");
            return ReturnValue.invalidEncodedValue;
        }
        catch (Exception e)
        {
            writeln("\n", e.msg, "\n");
            return ReturnValue.unexpectedException;
        }

        writeln();
        foreach (top; tops)
        {
            try
            {
                display(top, 0u);
            }
            catch (ASN1ValueSizeException e)
            {
                writeln("\n", e.msg, "\n");
                return ReturnValue.elementTerminatedPrematurely;
            }
            catch (ASN1Exception e)
            {
                writeln("\n", e.msg, "\n");
                return ReturnValue.invalidEncodedValue;
            }
            catch (Exception e)
            {
                writeln("\n", e.msg, "\n");
                return ReturnValue.unexpectedException;
            }
        }

        writeln();
        return ReturnValue.success;
    }

    void display (Element element, ubyte indentation)
    {
        string tagClassString = "";
        bool universal = false;
        switch (element.tagClass)
        {
            case (ASN1TagClass.universal):
            {
                tagClassString = "UNIV";
                universal = true;
                break;
            }
            case (ASN1TagClass.application):
            {
                tagClassString = "APPL";
                break;
            }
            case (ASN1TagClass.contextSpecific):
            {
                tagClassString = "CTXT";
                break;
            }
            case (ASN1TagClass.privatelyDefined):
            {
                tagClassString = "PRIV";
                break;
            }
            default: assert(0, "Impossible tagClass encountered!");
        }

        char[] indents;
        indents.length = indentation;
        indents[0 .. $] = ' ';

        if (element.construction == ASN1Construction.primitive)
        {
            if (universal)
                writefln("%s[ %s %d ] : %s", cast(string) indents, tagClassString, element.tagNumber, stringifyUniversalValue(element));
            else
                writefln("%s[ %s %d ] : %(%02X %)", cast(string) indents, tagClassString, element.tagNumber, element.value);
        }
        else
        {
            writefln("%s[ %s %d ] :", cast(string) indents, tagClassString, element.tagNumber);
            indentation += 4;
            ubyte[] value = element.value.dup;
            Element[] subs;
            size_t i = 0u;
            while (i < value.length)
                subs ~= new Element(i, value);

            foreach (sub; subs)
            {
                display(new Element(element.value), indentation);
            }
        }
        indentation -= 4;
    }

    string stringifyUniversalValue (Element element)
    {
        import std.conv : text;
        switch (element.tagNumber)
        {
            case (0u): return "END OF CONTENT";
            case (1u): return (element.boolean ? "TRUE" : "FALSE");
            case (2u): return text(element.integer!ptrdiff_t);
            case (3u): return "BIT STRING";
            case (4u): return text(element.octetString);
            case (5u): return "NULL";
            case (6u): return element.objectIdentifier.toString();
            case (7u): return element.objectDescriptor;
            case (8u): return "EXTERNAL"; // This should never be executed.
            case (9u): return text(element.realNumber!double);
            case (10u): return text(element.enumerated!ptrdiff_t);
            case (11u): return "EmbeddedPDV"; // This should never be executed.
            case (12u): return element.utf8String;
            case (13u): return ("RELATIVE OID: " ~ text(element.value));
            case (14u): return "!!! INVALID TYPE : RESERVED 14 !!!";
            case (15u): return "!!! INVALID TYPE : RESERVED 15 !!!";
            case (16u): return "SEQUENCE"; // This should never be executed.
            case (17u): return "SET"; // This should never be executed.
            case (18u): return element.numericString;
            case (19u): return element.printableString;
            case (20u): return text(element.teletexString);
            case (21u): return text(element.videotexString);
            case (22u): return element.ia5String;
            case (23u): return element.utcTime.toISOString();
            case (24u): return element.generalizedTime.toISOString();
            case (25u): return element.graphicString;
            case (26u): return element.visibleString;
            case (27u): return element.generalString;
            case (28u): return "[ UniversalString that cannot be displayed. ]";
            case (29u): return "CharacterString"; // This should never be executed.
            case (30u): return "[ BMPString that cannot be displayed. ]";
            case (31u): return "!!! INVALID TYPE : UNDEFINED 31 !!!";
            default: return "!!! INVALID TYPE : tagNumber above 31 !!!";
        }
    }
}