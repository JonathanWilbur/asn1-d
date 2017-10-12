module types.universal.objectdescriptor;
import asn1;
// import types.types : ASN1UniversalType, ASN1UniversalTypeTag;

/**
    Thrown if an Object Descriptor contains non-Graphical characters. See
    $(LINK2 https://en.wikipedia.org/wiki/Graphic_character, Wikipedia: Graphic Characters)
    for more information. Also, see
    $(LINK2 https://dlang.org/phobos/std_ascii.html#.isGraphical, std.ascii.isGraphical).
*/
class ASN1ObjectDescriptorException : ASN1Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

/*
    Page 198
    ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString
*/
public class ObjectDescriptor
//: ASN1UniversalType
{
    // override public @property
    // ASN1UniversalTypeTag typeTag()
    // {
    //     return ASN1UniversalTypeTag.objectDescriptor; // 0x07
    // }

    public static size_t lengthLimit = 65536;

    private string _value;

    public @property
    string value()
    {
        return this._value;
    }

    public @property
    void value(string value)
    {
        import std.conv : text;
        if (value.length > this.lengthLimit)
        {
            throw new ASN1ObjectDescriptorException(
                "Object descriptor exceeded the configured length limit of " ~
                text(this.lengthLimit));
        }

        import std.ascii : isGraphical;
        foreach (character; value)
        {
            if (!character.isGraphical)
            {
                throw new ASN1ObjectDescriptorException(
                    "Object descriptor can only contain graphical characters. '"
                    ~ character ~ "' is not graphical.");
            }
        }

        this._value = value;
    }

    this(string value)
    {
        this.value = value;
    }

    public @property
    size_t length()
    {
        return this._value.length;
    }
}
