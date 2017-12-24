/**
    The codecs in this library are values of an ASN1 encoding scheme.
    The type, length, and value are set using properties defined on
    abstract classes from which the encoding-specific values inherit.
    This module contains those abstract classes, and with these classes,
    it serves as the root module from which all other codec modules will
    inherit.
*/
module codec;
public import asn1;
public import types.alltypes;
public import types.identification;
public import types.oidtype;
public import std.algorithm.mutation : reverse;
public import std.algorithm.searching : canFind;
public import std.ascii : isASCII, isGraphical;
public import std.conv : text;
public import std.datetime.date : DateTime;
public import std.datetime.systime : SysTime;
public import std.datetime.timezone : TimeZone, UTC;
private import std.exception : basicExceptionCtors;
public import std.math : isNaN, log2;
public import std.traits : isIntegral, isSigned, isUnsigned;

///
public alias ASN1CodecException = AbstractSyntaxNotation1CodecException;
/// A generic exception from which any ASN.1 codec exception may inherit
public
class AbstractSyntaxNotation1CodecException : ASN1Exception
{
    mixin basicExceptionCtors;
}

///
public alias ASN1RecursionException = AbstractSyntaxNotation1RecursionException;
/// An exception that is thrown when excessively deep recursion occurs.
public
class AbstractSyntaxNotation1RecursionException : ASN1CodecException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1TagException = AbstractSyntaxNotation1TagException;
///
public
class AbstractSyntaxNotation1TagException : ASN1CodecException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1ValueSizeException = AbstractSyntaxNotation1ValueSizeException;
///
public
class AbstractSyntaxNotation1ValueSizeException : ASN1CodecException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1ValueTooBigException = AbstractSyntaxNotation1ValueTooBigException;
///
public
class AbstractSyntaxNotation1ValueTooBigException : ASN1ValueSizeException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1ValueTooSmallException = AbstractSyntaxNotation1ValueTooSmallException;
///
public
class AbstractSyntaxNotation1ValueTooSmallException : ASN1ValueSizeException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1ValueInvalidException = AbstractSyntaxNotation1ValueInvalidException;
/**
    Thrown when an encoded value, or a decoded value (attempting to be encoded)
    takes on a value that the codec cannot encode or decode.

    Examples:
    $(UL
        $(LI When a DER codec detects a BOOLEAN encoded in a byte other than 0xFF or 0x00)
        $(LI When a BER codec finds an invalid character in a string)
    )
*/
public
class AbstractSyntaxNotation1ValueInvalidException : ASN1CodecException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1InvalidIndexException = AbstractSyntaxNotation1InvalidIndexException;
/**
    An exception thrown when a member of a CHOICE or SEQUENCE is given a
    context-specific index that is not defined for that CHOICE or SEQUENCE.

    For example, if:

    TheQuestion := [APPLICATION 5] CHOICE {
        toBe [0] NULL,
        notToBe [1] NULL
    }

    This exception should be thrown if TheQuestion were to be decoded from the
    BER-encoded byte sequence: $(D_INLINECODE 0x65 0x02 0x83 0x00), because
    the third byte specifies a third choice in TheQuestion, but there is no
    choice #3 in TheQuestion--there is only choice #0 and #1.
*/
public
class AbstractSyntaxNotation1InvalidIndexException : ASN1CodecException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1InvalidLengthException = AbstractSyntaxNotation1InvalidLengthException;
/**
    Thrown if an invalid length encoding is encountered, such as when a length byte
    of 0xFF--which is reserved--is encountered in BER encoding.
*/
public
class AbstractSyntaxNotation1InvalidLengthException : ASN1CodecException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1Element = AbstractSyntaxNotation1Element;
///
abstract public
class AbstractSyntaxNotation1Element(Element)
{
    static assert(is(Element : typeof(this)), "Tried to instantiate " ~ typeof(this).stringof ~ " with type parameter " ~ Element.stringof);

    @system
    unittest
    {
        writeln("Running unit tests for ASN1Element template for codec: " ~ Element.stringof);
    }

    // Constants used to save CPU cycles
    protected immutable real maxUintAsReal = cast(real) uint.max; // Saves CPU cycles in realType()
    protected immutable real maxLongAsReal = cast(real) long.max; // Saves CPU cycles in realType()
    protected immutable real logBaseTwoOfTen = log2(10.0); // Saves CPU cycles in realType()

    // Constants for exception messages
    immutable string notWhatYouMeantText =
        "It is highly likely that what you attempted to decode was not the " ~
        "data type that you thought it was. Most likely, one of the following " ~
        "scenarios occurred: (1) you did not write this program to the exact " ~
        "specification of the protocol, or (2) someone is attempting to hack " ~
        "this program (review the HeartBleed bug), or (3) the client sent " ~
        "valid data that was just too big to decode. ";
    immutable string forMoreInformationText =
        "For more information on the specific method or property that originated " ~
        "this exception, see the documentation associated with this ASN.1 " ~
        "library. For more information on ASN.1's data types in general, see " ~
        "the International Telecommunications Union's X.680 specification, " ~
        "which can be found at: " ~
        "https://www.itu.int/ITU-T/studygroups/com17/languages/X.680-0207.pdf. " ~
        "For more information on how those data types are supposed to be " ~
        "encoded using Basic Encoding Rules, Canonical Encoding Rules, or " ~
        "Distinguished Encoding Rules, see the International " ~
        "Telecommunications Union's X.690 specification, which can be found " ~
        "at: https://www.itu.int/ITU-T/studygroups/com17/languages/X.690-0207.pdf. ";
    immutable string debugInformationText =
        "If reviewing the documentation does not help, you may want to run " ~
        "the ASN.1 library in debug mode. To do this, compile the source code " ~
        "for this library with the `-debug=asn1` flag (if you are compiling " ~
        "with `dmd`). This will display information to the console that may " ~
        "help you diagnose any issues. ";
    immutable string reportBugsText =
        "If none of the steps above helped, and you believe that you have " ~
        "discovered a bug, please create an issue on the GitHub page's Issues " ~
        "section at: https://github.com/JonathanWilbur/asn1-d/issues. ";

    ///
    immutable public
    enum LengthEncodingPreference : ubyte
    {
        definite,
        indefinite
    }

    /// Decodes a boolean
    abstract public @property
    bool boolean() const;

    /// Encodes a boolean
    abstract public @property
    void boolean(in bool value);

    @system
    unittest
    {
        Element el = new Element();
        el.boolean = true;
        assert(el.boolean == true);
        el.boolean = false;
        assert(el.boolean == false);

        // Assert that accessor does not mutate state
        assert(el.boolean == el.boolean);
    }

    /// Decodes an integer
    abstract public @property
    T integer(T)() const if (isIntegral!T && isSigned!T);

    /// Encodes an integer
    abstract public @property
    void integer(T)(in T value) if (isIntegral!T && isSigned!T);

    // Test all 255 signed 8-bit integers
    @system
    unittest
    {
        Element el = new Element();
        for (byte i = byte.min; i < byte.max; i++)
        {
            el.integer!byte = i;
            assert(el.integer!byte == i);
            el.integer!short = i;
            assert(el.integer!short == i);
            el.integer!int = i;
            assert(el.integer!int == i);
            el.integer!long = i;
            assert(el.integer!long == i);
        }
    }

    // Test all 65536 signed 16-bit integers
    @system
    unittest
    {
        Element el = new Element();
        for (short i = short.min; i < short.max; i++)
        {
            el.integer!short = i;
            assert(el.integer!short == i);
            el.integer!int = i;
            assert(el.integer!int == i);
            el.integer!long = i;
            assert(el.integer!long == i);
        }
    }

    // Test a few signed 32-bit integers
    @system
    unittest
    {
        Element el = new Element();
        for (int i = int.min; i < int.max-15_485_863; i += 15_485_863) // 15,485,863 is the millionth prime
        {
            ubyte[] ub;
            ub.length = int.sizeof;
            *cast(int *)&ub[0] = i;
            version (LittleEndian) reverse(ub);
            el.integer!int = i;
            assert(el.integer!int == i);
            el.integer!long = i;
            assert(el.integer!long == i);
        }
    }

    // Test a few signed 64-bit integers
    @system
    unittest
    {
        Element el = new Element();
        for (long i = long.min; i < long.max-965_211_250_482_432_409; i += 965_211_250_482_432_409) // 50 millionth prime^2
        {
            el.integer!long = i;
            assert(el.integer!long == i);
        }
    }

    @system
    unittest
    {
        Element el = new Element();

        // Tests for zero
        el.integer!byte = 0;
        assert(el.integer!byte == 0);
        assert(el.integer!short == 0);
        assert(el.integer!int == 0);
        assert(el.integer!long == 0L);

        el.integer!short = 0;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        assert(el.integer!short == 0);
        assert(el.integer!int == 0);
        assert(el.integer!long == 0L);

        el.integer!int = 0;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        assert(el.integer!int == 0);
        assert(el.integer!long == 0L);

        el.integer!long = 0L;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        // assertThrown!ASN1ValueTooBigException(el.integer!int);
        assert(el.integer!long == 0L);

        // Tests for small positives
        el.integer!byte = 3;
        assert(el.integer!byte == 3);
        assert(el.integer!short == 3);
        assert(el.integer!int == 3);
        assert(el.integer!long == 3L);

        el.integer!short = 5;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        assert(el.integer!short == 5);
        assert(el.integer!int == 5);
        assert(el.integer!long == 5L);

        el.integer!int = 7;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        assert(el.integer!int == 7);
        assert(el.integer!long == 7L);

        el.integer!long = 9L;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        // assertThrown!ASN1ValueTooBigException(el.integer!int);
        assert(el.integer!long == 9L);

        // Tests for small negatives
        el.integer!byte = -3;
        assert(el.integer!byte == -3);
        assert(el.integer!short == -3);
        assert(el.integer!int == -3);
        assert(el.integer!long == -3L);

        el.integer!short = -5;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        assert(el.integer!short == -5);
        assert(el.integer!int == -5);
        assert(el.integer!long == -5L);

        el.integer!int = -7;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        assert(el.integer!int == -7);
        assert(el.integer!long == -7L);

        el.integer!long = -9L;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        // assertThrown!ASN1ValueTooBigException(el.integer!int);
        assert(el.integer!long == -9L);

        // Tests for large positives
        el.integer!short = 20000;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        assert(el.integer!short == 20000);
        assert(el.integer!int == 20000);
        assert(el.integer!long == 20000L);

        el.integer!int = 70000;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        assert(el.integer!int == 70000);
        assert(el.integer!long == 70000L);

        el.integer!long = 70000L;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        // assertThrown!ASN1ValueTooBigException(el.integer!int);
        assert(el.integer!long == 70000L);

        // Tests for large negatives
        el.integer!short = -20000;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        assert(el.integer!short == -20000);
        assert(el.integer!int == -20000);
        assert(el.integer!long == -20000L);

        el.integer!int = -70000;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        assert(el.integer!int == -70000);
        assert(el.integer!long == -70000L);

        el.integer!long = -70000L;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        // assertThrown!ASN1ValueTooBigException(el.integer!int);
        assert(el.integer!long == -70000L);

        // Tests for maximum values
        el.integer!byte = byte.max;
        assert(el.integer!byte == byte.max);
        assert(el.integer!short == byte.max);
        assert(el.integer!int == byte.max);
        assert(el.integer!long == byte.max);

        el.integer!short = short.max;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        assert(el.integer!short == short.max);
        assert(el.integer!int == short.max);
        assert(el.integer!long == short.max);

        el.integer!int = int.max;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        assert(el.integer!int == int.max);
        assert(el.integer!long == int.max);

        el.integer!long = long.max;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        // assertThrown!ASN1ValueTooBigException(el.integer!int);
        assert(el.integer!long == long.max);

        // Tests for minimum values
        el.integer!byte = byte.min;
        assert(el.integer!byte == byte.min);
        assert(el.integer!short == byte.min);
        assert(el.integer!int == byte.min);
        assert(el.integer!long == byte.min);

        el.integer!short = short.min;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        assert(el.integer!short == short.min);
        assert(el.integer!int == short.min);
        assert(el.integer!long == short.min);

        el.integer!int = int.min;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        assert(el.integer!int == int.min);
        assert(el.integer!long == int.min);

        el.integer!long = long.min;
        // assertThrown!ASN1ValueTooBigException(el.integer!byte);
        // assertThrown!ASN1ValueTooBigException(el.integer!short);
        // assertThrown!ASN1ValueTooBigException(el.integer!int);
        assert(el.integer!long == long.min);

        // Assert that accessor does not mutate state
        assert(el.integer!long == el.integer!long);
    }

    abstract public @property
    bool[] bitString() const;

    abstract public @property
    void bitString(in bool[] value);

    @system
    unittest
    {
        Element el = new Element();
        el.bitString = []; // 0 bits
        assert(el.bitString == []);
        el.bitString = [ true, false, true, true, false, false, true ]; // 7 bits
        assert(el.bitString == [ true, false, true, true, false, false, true ]);
        el.bitString = [ true, false, true, true, false, false, true, false ]; // 8 bits
        assert(el.bitString == [ true, false, true, true, false, false, true, false ]);
        el.bitString = [ true, false, true, true, false, false, true, false, true ]; // 9 bits
        assert(el.bitString == [ true, false, true, true, false, false, true, false, true ]);

        // Assert that accessor does not mutate state
        assert(el.bitString == el.bitString);
    }

    /// Decodes a ubyte[] array
    abstract public @property
    ubyte[] octetString() const;

    /// Encodes a ubyte[] array
    abstract public @property
    void octetString(in ubyte[] value);

    @system
    unittest
    {
        Element el = new Element();
        el.octetString = [ 0x05u, 0x02u, 0xFFu, 0x00u, 0x6Au ];
        assert(el.octetString == [ 0x05u, 0x02u, 0xFFu, 0x00u, 0x6Au ]);

        // Assert that accessor does not mutate state
        assert(el.octetString == el.octetString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        ubyte[] test = [ 0x05u, 0x02u, 0xFFu, 0x00u, 0x6Au ];
        Element el = new Element();
        el.octetString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 0x6Au);
    }

    // Test that mutating a large value does not mutate an external reference.
    @system
    unittest
    {
        ubyte[] test;
        test.length = 10000u;
        Element el = new Element();
        el.octetString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 0x00u);
    }

    ///
    public alias oid = objectIdentifier;
    /// Decodes an Object Identifier
    abstract public @property
    OID objectIdentifier() const;

    /// Encodes an Object Identifier
    abstract public @property
    void objectIdentifier(in OID value);

    @system
    unittest
    {
        Element el = new Element();
        el.objectIdentifier = new OID(OIDNode(1u), OIDNode(30u), OIDNode(256u), OIDNode(623485u), OIDNode(8u));
        assert(el.objectIdentifier == new OID(OIDNode(1u), OIDNode(30u), OIDNode(256u), OIDNode(623485u), OIDNode(8u)));

        size_t[] sensitiveValues = [
            0,
            1,
            2, // First even
            3, // First odd greater than 1
            7, // Number of bits in each byte that encode the number
            8, // Number of bits in a byte
            127, // Largest number that can encode on a single OID byte
            128, // 127+1
            70000 // A large number that takes three bytes to encode
        ];

        for (size_t x = 0u; x < 2; x++)
        {
            for (size_t y = 0u; y < 40u; y++)
            {
                foreach (z; sensitiveValues)
                {
                    el.objectIdentifier = new OID(x, y, 6, 4, z);
                    assert(el.objectIdentifier.numericArray == [ x, y, 6, 4, z ]);
                    el.objectIdentifier = new OID(x, y, 6, 4, z, 0);
                    assert(el.objectIdentifier.numericArray == [ x, y, 6, 4, z, 0 ]);
                    el.objectIdentifier = new OID(x, y, 6, 4, z, 1);
                    assert(el.objectIdentifier.numericArray == [ x, y, 6, 4, z, 1 ]);
                    el.objectIdentifier = new OID(OIDNode(x), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z));
                    assert(el.objectIdentifier == new OID(OIDNode(x), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z)));
                    el.objectIdentifier = new OID(OIDNode(x), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z), OIDNode(0));
                    assert(el.objectIdentifier == new OID(OIDNode(x), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z), OIDNode(0)));
                    el.objectIdentifier = new OID(OIDNode(x), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z), OIDNode(1));
                    assert(el.objectIdentifier == new OID(OIDNode(x), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z), OIDNode(1)));
                }
            }
        }

        for (size_t y = 0u; y < 175u; y++)
        {
            foreach (z; sensitiveValues)
            {
                el.objectIdentifier = new OID(2, y, 6, 4, z);
                assert(el.objectIdentifier.numericArray == [ 2, y, 6, 4, z ]);
                el.objectIdentifier = new OID(2, y, 6, 4, z, 0);
                assert(el.objectIdentifier.numericArray == [ 2, y, 6, 4, z, 0 ]);
                el.objectIdentifier = new OID(2, y, 6, 4, z, 1);
                assert(el.objectIdentifier.numericArray == [ 2, y, 6, 4, z, 1 ]);
                el.objectIdentifier = new OID(OIDNode(2), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z));
                assert(el.objectIdentifier == new OID(OIDNode(2), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z)));
                el.objectIdentifier = new OID(OIDNode(2), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z), OIDNode(0));
                assert(el.objectIdentifier == new OID(OIDNode(2), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z), OIDNode(0)));
                el.objectIdentifier = new OID(OIDNode(2), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z), OIDNode(1));
                assert(el.objectIdentifier == new OID(OIDNode(2), OIDNode(y), OIDNode(256u), OIDNode(5u), OIDNode(z), OIDNode(1)));
            }
        }

        // Assert that accessor does not mutate state
        assert(el.objectIdentifier == el.objectIdentifier);
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
    */
    abstract public @property
    string objectDescriptor() const;

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
    */
    abstract public @property
    void objectDescriptor(in string value);

    @system
    unittest
    {
        Element el = new Element();
        el.objectDescriptor = "Nitro dubs & T-Rix";
        assert(el.objectDescriptor == "Nitro dubs & T-Rix");
        el.objectDescriptor = " ";
        assert(el.objectDescriptor == " ");
        el.objectDescriptor = "";
        assert(el.objectDescriptor == "");
        assertThrown!ASN1ValueInvalidException(el.objectDescriptor = "\xD7");
        assertThrown!ASN1ValueInvalidException(el.objectDescriptor = "\t");
        assertThrown!ASN1ValueInvalidException(el.objectDescriptor = "\r");
        assertThrown!ASN1ValueInvalidException(el.objectDescriptor = "\n");
        assertThrown!ASN1ValueInvalidException(el.objectDescriptor = "\b");
        assertThrown!ASN1ValueInvalidException(el.objectDescriptor = "\v");
        assertThrown!ASN1ValueInvalidException(el.objectDescriptor = "\f");
        assertThrown!ASN1ValueInvalidException(el.objectDescriptor = "\0");

        // Assert that accessor does not mutate state
        assert(el.objectDescriptor == el.objectDescriptor);
    }

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
    */
    deprecated abstract public @property
    External external() const;

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
    */
    deprecated abstract public @property
    void external(in External value);

    // Test of all pre-1994 External encoding choices
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.syntax = new OID(1, 3, 6, 4, 1, 256, 39);

        External input = External();
        External output;
        input.identification = id;
        input.dataValueDescriptor = "boop";
        input.dataValue = [ 0x03u, 0x05u, 0x07u, 0x09u ];

        Element el = new Element();

        // single-ASN1-type
        input.encoding = ASN1ExternalEncodingChoice.singleASN1Type;
        el.external = input;
        output = el.external;
        assert(output.identification.syntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.dataValueDescriptor == "boop");
        assert(output.dataValue == [ 0x03u, 0x05u, 0x07u, 0x09u ]);

        // octet-aligned
        input.encoding = ASN1ExternalEncodingChoice.octetAligned;
        el.external = input;
        output = el.external;
        assert(output.identification.syntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.dataValueDescriptor == "boop");
        assert(output.dataValue == [ 0x03u, 0x05u, 0x07u, 0x09u ]);

        // arbitrary
        input.encoding = ASN1ExternalEncodingChoice.arbitrary;
        el.external = input;
        output = el.external;
        assert(output.identification.syntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.dataValueDescriptor == "boop");
        assert(output.dataValue == [ 0x03u, 0x05u, 0x07u, 0x09u ]);
    }

    /// Encodes a floating-point number
    abstract public @property
    T realType(T)() const if (is(T == float) || is(T == double));

    /// Encodes a floating-point number
    abstract public @property
    void realType(T)(in T value) if (is(T == float) || is(T == double));

    ///
    @system
    unittest
    {
        float f = -22.86;
        double d = 0.00583;
        Element elf = new Element();
        Element eld = new Element();
        elf.realType!float = f;
        eld.realType!double = d;
        assert(approxEqual(elf.realType!float, f));
        assert(approxEqual(elf.realType!double, f));
        assert(approxEqual(eld.realType!float, d));
        assert(approxEqual(eld.realType!double, d));

        // Assert that accessor does not mutate state
        assert(approxEqual(elf.realType!double, elf.realType!double));
    }

    // Test a few edge cases
    @system
    unittest
    {
        Element el = new Element();

        // Positive Zeroes
        el.realType!float = 0.0;
        assert(approxEqual(el.realType!float, 0.0));
        assert(approxEqual(el.realType!double, 0.0));
        el.realType!double = 0.0;
        assert(approxEqual(el.realType!float, 0.0));
        assert(approxEqual(el.realType!double, 0.0));

        // Negative Zeroes
        el.realType!float = -0.0;
        assert(approxEqual(el.realType!float, -0.0));
        assert(approxEqual(el.realType!double, -0.0));
        el.realType!double = -0.0;
        assert(approxEqual(el.realType!float, -0.0));
        assert(approxEqual(el.realType!double, -0.0));

        // Positive Repeating decimal
        el.realType!float = (10.0 / 3.0);
        assert(approxEqual(el.realType!float, (10.0 / 3.0)));
        assert(approxEqual(el.realType!double, (10.0 / 3.0)));
        el.realType!double = (10.0 / 3.0);
        assert(approxEqual(el.realType!float, (10.0 / 3.0)));
        assert(approxEqual(el.realType!double, (10.0 / 3.0)));

        // Negative Repeating Decimal
        el.realType!float = -(10.0 / 3.0);
        assert(approxEqual(el.realType!float, -(10.0 / 3.0)));
        assert(approxEqual(el.realType!double, -(10.0 / 3.0)));
        el.realType!double = -(10.0 / 3.0);
        assert(approxEqual(el.realType!float, -(10.0 / 3.0)));
        assert(approxEqual(el.realType!double, -(10.0 / 3.0)));

        // Positive one
        el.realType!float = 1.0;
        assert(approxEqual(el.realType!float, 1.0));
        assert(approxEqual(el.realType!double, 1.0));
        el.realType!double = 1.0;
        assert(approxEqual(el.realType!float, 1.0));
        assert(approxEqual(el.realType!double, 1.0));

        // Negative one
        el.realType!float = -1.0;
        assert(approxEqual(el.realType!float, -1.0));
        assert(approxEqual(el.realType!double, -1.0));
        el.realType!double = -1.0;
        assert(approxEqual(el.realType!float, -1.0));
        assert(approxEqual(el.realType!double, -1.0));

        // Positive Infinity
        el.realType!float = float.infinity;
        assert(el.realType!float == float.infinity);
        assert(el.realType!double == double.infinity);
        el.realType!double = double.infinity;
        assert(el.realType!float == float.infinity);
        assert(el.realType!double == double.infinity);

        // Negative Infinity
        el.realType!float = -float.infinity;
        assert(el.realType!float == -float.infinity);
        assert(el.realType!double == -double.infinity);
        el.realType!double = -double.infinity;
        assert(el.realType!float == -float.infinity);
        assert(el.realType!double == -double.infinity);

        // Not-a-Number
        assertThrown!ASN1ValueInvalidException(el.realType!float = float.nan);
        assertThrown!ASN1ValueInvalidException(el.realType!double = double.nan);
    }

    // Tests of maximum and minimums of integral types
    @system
    unittest
    {
        Element el = new Element();

        el.realType!float = cast(float) byte.max;
        approxEqual(el.realType!float, byte.max);
        el.realType!double = cast(double) byte.max;
        approxEqual(el.realType!double, byte.max);

        el.realType!float = cast(float) byte.min;
        approxEqual(el.realType!float, byte.min);
        el.realType!double = cast(double) byte.min;
        approxEqual(el.realType!double, byte.min);

        el.realType!float = cast(float) ubyte.max;
        approxEqual(el.realType!float, ubyte.max);
        el.realType!double = cast(double) ubyte.max;
        approxEqual(el.realType!double, byte.max);

        el.realType!float = cast(float) ubyte.min;
        approxEqual(el.realType!float, ubyte.min);
        el.realType!double = cast(double) ubyte.min;
        approxEqual(el.realType!double, ubyte.min);

        el.realType!float = cast(float) short.max;
        approxEqual(el.realType!float, short.max);
        el.realType!double = cast(double) short.max;
        approxEqual(el.realType!double, short.max);

        el.realType!float = cast(float) short.min;
        approxEqual(el.realType!float, short.min);
        el.realType!double = cast(double) short.min;
        approxEqual(el.realType!double, short.min);

        el.realType!float = cast(float) ushort.max;
        approxEqual(el.realType!float, ushort.max);
        el.realType!double = cast(double) ushort.max;
        approxEqual(el.realType!double, ushort.max);

        el.realType!float = cast(float) ushort.min;
        approxEqual(el.realType!float, ushort.min);
        el.realType!double = cast(double) ushort.min;
        approxEqual(el.realType!double, ushort.min);

        el.realType!float = cast(float) int.max;
        approxEqual(el.realType!float, int.max);
        el.realType!double = cast(double) int.max;
        approxEqual(el.realType!double, int.max);

        el.realType!float = cast(float) int.min;
        approxEqual(el.realType!float, int.min);
        el.realType!double = cast(double) int.min;
        approxEqual(el.realType!double, int.min);

        el.realType!float = cast(float) uint.max;
        approxEqual(el.realType!float, uint.max);
        el.realType!double = cast(double) uint.max;
        approxEqual(el.realType!double, uint.max);

        el.realType!float = cast(float) uint.min;
        approxEqual(el.realType!float, uint.min);
        el.realType!double = cast(double) uint.min;
        approxEqual(el.realType!double, uint.min);

        el.realType!float = cast(float) long.max;
        approxEqual(el.realType!float, long.max);
        el.realType!double = cast(double) long.max;
        approxEqual(el.realType!double, long.max);

        el.realType!float = cast(float) long.min;
        approxEqual(el.realType!float, long.min);
        el.realType!double = cast(double) long.min;
        approxEqual(el.realType!double, long.min);

        el.realType!float = cast(float) ulong.max;
        approxEqual(el.realType!float, ulong.max);
        el.realType!double = cast(double) ulong.max;
        approxEqual(el.realType!double, ulong.max);

        el.realType!float = cast(float) ulong.min;
        approxEqual(el.realType!float, ulong.min);
        el.realType!double = cast(double) ulong.min;
        approxEqual(el.realType!double, ulong.min);
    }

    // Tests of maximum and minimums of floating-point types
    @system
    unittest
    {
        Element el = new Element();

        // Maximums and minimums of floats
        el.realType!float = float.max;
        approxEqual(el.realType!float, float.max);
        el.realType!double = cast(double) float.max;
        approxEqual(el.realType!double, float.max);

        el.realType!float = float.max_10_exp;
        approxEqual(el.realType!float, float.max_10_exp);
        el.realType!double = cast(double) float.max_10_exp;
        approxEqual(el.realType!double, float.max_10_exp);

        el.realType!float = float.max_exp;
        approxEqual(el.realType!float, float.max_exp);
        el.realType!double = cast(double) float.max_exp;
        approxEqual(el.realType!double, float.max_exp);

        el.realType!float = float.min_10_exp;
        approxEqual(el.realType!float, float.min_10_exp);
        el.realType!double = cast(double) float.min_10_exp;
        approxEqual(el.realType!double, float.min_10_exp);

        el.realType!float = float.min_exp;
        approxEqual(el.realType!float, float.min_exp);
        el.realType!double = cast(double) float.min_exp;
        approxEqual(el.realType!double, float.min_exp);

        el.realType!float = float.min_normal;
        approxEqual(el.realType!float, float.min_normal);
        el.realType!double = cast(double) float.min_normal;
        approxEqual(el.realType!double, float.min_normal);

        // Maximums and minimums of doubles
        el.realType!double = cast(double) double.max;
        approxEqual(el.realType!double, double.max);

        el.realType!double = cast(double) double.max_10_exp;
        approxEqual(el.realType!double, double.max_10_exp);

        el.realType!double = cast(double) double.max_exp;
        approxEqual(el.realType!double, double.max_exp);

        el.realType!double = cast(double) double.min_10_exp;
        approxEqual(el.realType!double, double.min_10_exp);

        el.realType!double = cast(double) double.min_exp;
        approxEqual(el.realType!double, double.min_exp);

        el.realType!double = cast(double) double.min_normal;
        approxEqual(el.realType!double, double.min_normal);
    }

    // Test with all of the math constants, to make sure there are no edge cases.
    @system
    unittest
    {
        import std.math :
            E, PI, PI_2, PI_4, M_1_PI, M_2_PI, M_2_SQRTPI, LN10, LN2, LOG2,
            LOG2E, LOG2T, LOG10E, SQRT2, SQRT1_2, sqrt;

        immutable real SQRT_2_OVER_2 = (SQRT2 / 2.0);

        // Sourced from https://en.wikipedia.org/wiki/Mathematical_constant
        immutable real EULER_MASCHERONI_CONSTANT = 0.57721;
        immutable real GOLDEN_RATIO = ((1.0 + sqrt(5.0)) / 2.0);
        immutable real MEISSEL_MERTENS_CONSTANT = 0.2614972128;
        immutable real BERNSTEINS_CONSTANT = 0.2801694990;
        immutable real GAUSS_KUZMIN_WIRSING_CONSTANT = 0.3036630028;
        immutable real HAFNER_SARNAK_MCCURLEY_CONSTANT = 0.3532363718;
        immutable real OMEGA_CONSTANT = 0.5671432904;
        immutable real GOLOMB_DICKMAN_CONSTANT = 0.6243299885;
        immutable real CAHENS_CONSTANT = 0.6434105462;
        immutable real TWIN_PRIME_CONSTANT = 0.6601618158;
        immutable real LAPLACE_LIMIT = 0.6627434193;
        immutable real LANDAU_RAMANUJAN_CONSTANT = 0.70258;
        immutable real ALLADI_GRINSTEAD_CONSTANT = 0.8093940205;
        immutable real BRUNS_CONSTANT_FOR_PRIME_QUADRUPLETS = 0.87058838;
        immutable real CATALANS_CONSTANT = 0.9159655941;
        immutable real LENGYELS_CONSTANT = 1.0986858055;
        immutable real VISWANATHS_CONSTANT = 1.13198824;
        immutable real APERYS_CONSTANT = 1.2020569;
        immutable real CONWAYS_CONSTANT = 1.30357;
        immutable real MILLS_CONSTANT = 1.3063778838;
        immutable real PLASTIC_CONSTANT = 1.3247179572;
        immutable real RAMANUJAN_SOLDNER_CONSTANT = 1.4513692348;
        immutable real BACKHOUSES_CONSTANT = 1.4560749485;
        immutable real PORTERS_CONSTANT = 1.4670780794;
        immutable real LIEBS_SQUARE_ICE_CONSTANT = 1.5396007178;
        immutable real ERDOS_BORWEIN_CONSTANT = 1.6066951524;
        immutable real NIVENS_CONSTANT = 1.7052111401;
        immutable real BRUNS_CONSTANT_FOR_TWIN_PRIMES = 1.9021605831;
        immutable real UNIVERSAL_PARABOLIC_CONSTANT = 2.2955871493;
        immutable real FEIGENBAUM_CONSTANT_ALPHA = 2.5029078750;
        immutable real SIERPINSKIS_CONSTANT = 2.5849817595;
        immutable real KHINCHINS_CONSTANT = 2.6854520010;
        immutable real FRANSEN_ROBINSON_CONSTANT = 2.8077702420;
        immutable real LEVYS_CONSTANT = 3.2758229187;
        immutable real RECIPROCAL_FIBONACCI_CONSTANT = 3.3598856662;
        immutable real FEIGENBAUM_CONSTANT_DELTA = 4.6692016091;
        immutable real GLAISHER_KINKELIN_CONSTANT = 1.2824271291;

        immutable real[] tests = [
            E, PI, PI_2, PI_4, M_1_PI, M_2_PI, M_2_SQRTPI, LN10, LN2, LOG2,
            LOG2E, LOG2T, LOG10E, SQRT2, SQRT1_2, SQRT_2_OVER_2,
            EULER_MASCHERONI_CONSTANT,
            GOLDEN_RATIO,
            MEISSEL_MERTENS_CONSTANT,
            BERNSTEINS_CONSTANT,
            GAUSS_KUZMIN_WIRSING_CONSTANT,
            HAFNER_SARNAK_MCCURLEY_CONSTANT,
            OMEGA_CONSTANT,
            GOLOMB_DICKMAN_CONSTANT,
            CAHENS_CONSTANT,
            TWIN_PRIME_CONSTANT,
            LAPLACE_LIMIT,
            LANDAU_RAMANUJAN_CONSTANT,
            ALLADI_GRINSTEAD_CONSTANT,
            BRUNS_CONSTANT_FOR_PRIME_QUADRUPLETS,
            CATALANS_CONSTANT,
            LENGYELS_CONSTANT,
            VISWANATHS_CONSTANT,
            APERYS_CONSTANT,
            CONWAYS_CONSTANT,
            MILLS_CONSTANT,
            PLASTIC_CONSTANT,
            RAMANUJAN_SOLDNER_CONSTANT,
            BACKHOUSES_CONSTANT,
            PORTERS_CONSTANT,
            LIEBS_SQUARE_ICE_CONSTANT,
            ERDOS_BORWEIN_CONSTANT,
            NIVENS_CONSTANT,
            BRUNS_CONSTANT_FOR_TWIN_PRIMES,
            UNIVERSAL_PARABOLIC_CONSTANT,
            FEIGENBAUM_CONSTANT_ALPHA,
            SIERPINSKIS_CONSTANT,
            KHINCHINS_CONSTANT,
            FRANSEN_ROBINSON_CONSTANT,
            LEVYS_CONSTANT,
            RECIPROCAL_FIBONACCI_CONSTANT,
            FEIGENBAUM_CONSTANT_DELTA,
            GLAISHER_KINKELIN_CONSTANT
        ];

        Element el = new Element();

        foreach (test; tests)
        {
            el.realType!float = cast(float) test;
            assert(approxEqual(el.realType!float, cast(float) test));
            el.realType!double = cast(double) test;
            assert(approxEqual(el.realType!double, cast(double) test));
        }
    }

    @system
    unittest
    {
        for (int i = -100; i < 100; i++)
        {
            // Alternating negative and positive floating point numbers exploring extreme values
            immutable float f = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            immutable double d = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            Element elf = new Element();
            Element eld = new Element();
            elf.realType!float = f;
            eld.realType!double = d;
            assert(approxEqual(elf.realType!float, f));
            assert(approxEqual(elf.realType!double, f));
            assert(approxEqual(eld.realType!float, d));
            assert(approxEqual(eld.realType!double, d));
        }
    }

    /// Encodes an integer that represents an ENUMERATED value
    abstract public @property
    T enumerated(T)() const if (isIntegral!T && isSigned!T);

    /// Decodes an integer that represents an ENUMERATED value
    abstract public @property
    void enumerated(T)(in T value) if (isIntegral!T && isSigned!T);

    // Test all 255 signed 8-bit integers
    @system
    unittest
    {
        Element el = new Element();
        for (byte i = byte.min; i < byte.max; i++)
        {
            el.enumerated!byte = i;
            assert(el.enumerated!byte == i);
            el.enumerated!short = i;
            assert(el.enumerated!short == i);
            el.enumerated!int = i;
            assert(el.enumerated!int == i);
            el.enumerated!long = i;
            assert(el.enumerated!long == i);
        }
    }

    // Test all 65536 signed 16-bit integers
    @system
    unittest
    {
        Element el = new Element();
        for (short i = short.min; i < short.max; i++)
        {
            el.enumerated!short = i;
            assert(el.enumerated!short == i);
            el.enumerated!int = i;
            assert(el.enumerated!int == i);
            el.enumerated!long = i;
            assert(el.enumerated!long == i);
        }
    }

    // Test a few signed 32-bit integers
    @system
    unittest
    {
        Element el = new Element();
        for (int i = int.min; i < int.max-15_485_863; i += 15_485_863) // 15,485,863 is the millionth prime
        {
            ubyte[] ub;
            ub.length = int.sizeof;
            *cast(int *)&ub[0] = i;
            version (LittleEndian) reverse(ub);
            el.enumerated!int = i;
            assert(el.enumerated!int == i);
            el.enumerated!long = i;
            assert(el.enumerated!long == i);
        }
    }

    // Test a few signed 64-bit integers
    @system
    unittest
    {
        Element el = new Element();
        for (long i = long.min; i < long.max-965_211_250_482_432_409; i += 965_211_250_482_432_409) // 50 millionth prime^2
        {
            el.enumerated!long = i;
            assert(el.enumerated!long == i);
        }
    }

    @system
    unittest
    {
        Element el = new Element();

        // Tests for zero
        el.enumerated!byte = 0;
        assert(el.enumerated!byte == 0);
        assert(el.enumerated!short == 0);
        assert(el.enumerated!int == 0);
        assert(el.enumerated!long == 0L);

        el.enumerated!short = 0;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        assert(el.enumerated!short == 0);
        assert(el.enumerated!int == 0);
        assert(el.enumerated!long == 0L);

        el.enumerated!int = 0;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        assert(el.enumerated!int == 0);
        assert(el.enumerated!long == 0L);

        el.enumerated!long = 0L;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!int);
        assert(el.enumerated!long == 0L);

        // Tests for small positives
        el.enumerated!byte = 3;
        assert(el.enumerated!byte == 3);
        assert(el.enumerated!short == 3);
        assert(el.enumerated!int == 3);
        assert(el.enumerated!long == 3L);

        el.enumerated!short = 5;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        assert(el.enumerated!short == 5);
        assert(el.enumerated!int == 5);
        assert(el.enumerated!long == 5L);

        el.enumerated!int = 7;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        assert(el.enumerated!int == 7);
        assert(el.enumerated!long == 7L);

        el.enumerated!long = 9L;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!int);
        assert(el.enumerated!long == 9L);

        // Tests for small negatives
        el.enumerated!byte = -3;
        assert(el.enumerated!byte == -3);
        assert(el.enumerated!short == -3);
        assert(el.enumerated!int == -3);
        assert(el.enumerated!long == -3L);

        el.enumerated!short = -5;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        assert(el.enumerated!short == -5);
        assert(el.enumerated!int == -5);
        assert(el.enumerated!long == -5L);

        el.enumerated!int = -7;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        assert(el.enumerated!int == -7);
        assert(el.enumerated!long == -7L);

        el.enumerated!long = -9L;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!int);
        assert(el.enumerated!long == -9L);

        // Tests for large positives
        el.enumerated!short = 20000;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        assert(el.enumerated!short == 20000);
        assert(el.enumerated!int == 20000);
        assert(el.enumerated!long == 20000L);

        el.enumerated!int = 70000;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        assert(el.enumerated!int == 70000);
        assert(el.enumerated!long == 70000L);

        el.enumerated!long = 70000L;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!int);
        assert(el.enumerated!long == 70000L);

        // Tests for large negatives
        el.enumerated!short = -20000;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        assert(el.enumerated!short == -20000);
        assert(el.enumerated!int == -20000);
        assert(el.enumerated!long == -20000L);

        el.enumerated!int = -70000;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        assert(el.enumerated!int == -70000);
        assert(el.enumerated!long == -70000L);

        el.enumerated!long = -70000L;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!int);
        assert(el.enumerated!long == -70000L);

        // Tests for maximum values
        el.enumerated!byte = byte.max;
        assert(el.enumerated!byte == byte.max);
        assert(el.enumerated!short == byte.max);
        assert(el.enumerated!int == byte.max);
        assert(el.enumerated!long == byte.max);

        el.enumerated!short = short.max;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        assert(el.enumerated!short == short.max);
        assert(el.enumerated!int == short.max);
        assert(el.enumerated!long == short.max);

        el.enumerated!int = int.max;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        assert(el.enumerated!int == int.max);
        assert(el.enumerated!long == int.max);

        el.enumerated!long = long.max;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!int);
        assert(el.enumerated!long == long.max);

        // Tests for minimum values
        el.enumerated!byte = byte.min;
        assert(el.enumerated!byte == byte.min);
        assert(el.enumerated!short == byte.min);
        assert(el.enumerated!int == byte.min);
        assert(el.enumerated!long == byte.min);

        el.enumerated!short = short.min;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        assert(el.enumerated!short == short.min);
        assert(el.enumerated!int == short.min);
        assert(el.enumerated!long == short.min);

        el.enumerated!int = int.min;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        assert(el.enumerated!int == int.min);
        assert(el.enumerated!long == int.min);

        el.enumerated!long = long.min;
        // assertThrown!ASN1ValueTooBigException(el.enumerated!byte);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!short);
        // assertThrown!ASN1ValueTooBigException(el.enumerated!int);
        assert(el.enumerated!long == long.min);

        // Assert that accessor does not mutate state
        assert(el.enumerated!long == el.enumerated!long);
    }

    ///
    public alias embeddedPDV = embeddedPresentationDataValue;
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
    */
    abstract public @property
    EmbeddedPDV embeddedPresentationDataValue() const;

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
    */
    abstract public @property
    void embeddedPresentationDataValue(in EmbeddedPDV value);

    @system
    unittest
    {
        ASN1Syntaxes syn = ASN1Syntaxes();
        syn.abstractSyntax = new OID(1, 3, 6, 4, 1, 256, 7);
        syn.transferSyntax = new OID(1, 3, 6, 4, 1, 256, 8);

        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.syntaxes = syn;

        EmbeddedPDV input = EmbeddedPDV();
        input.identification = id;
        input.dataValue = [ 0x03u, 0x05u, 0x07u, 0x09u ];

        Element el = new Element();
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.syntaxes.abstractSyntax == new OID(1, 3, 6, 4, 1, 256, 7));
        assert(output.identification.syntaxes.transferSyntax == new OID(1, 3, 6, 4, 1, 256, 8));
        assert(output.dataValue == [ 0x03u, 0x05u, 0x07u, 0x09u ]);

        // Assert that accessor does not mutate state
        assert(el.embeddedPDV == el.embeddedPDV);
    }

    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.syntax = new OID(1, 3, 6, 4, 1, 256, 39);

        EmbeddedPDV input = EmbeddedPDV();
        input.identification = id;
        input.dataValue = [ 0x03u, 0x05u, 0x07u, 0x09u ];

        Element el = new Element();
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.syntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.dataValue == [ 0x03u, 0x05u, 0x07u, 0x09u ]);
    }

    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.transferSyntax = new OID(1, 3, 6, 4, 1, 256, 39);

        EmbeddedPDV input = EmbeddedPDV();
        input.identification = id;
        input.dataValue = [ 0x03u, 0x05u, 0x07u, 0x09u ];

        Element el = new Element();
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.transferSyntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.dataValue == [ 0x03u, 0x05u, 0x07u, 0x09u ]);
    }

    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.fixed = true;

        EmbeddedPDV input = EmbeddedPDV();
        input.identification = id;
        input.dataValue = [ 0x03u, 0x05u, 0x07u, 0x09u ];

        Element el = new Element();
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.fixed == true);
        assert(output.dataValue == [ 0x03u, 0x05u, 0x07u, 0x09u ]);
    }

    ///
    public alias utf8String = unicodeTransformationFormat8String;
    /// Decodes a UTF-8 String
    abstract public @property
    string unicodeTransformationFormat8String() const;

    /// Encodes a UTF-8 String
    abstract public @property
    void unicodeTransformationFormat8String(in string value);

    @system
    unittest
    {
        Element el = new Element();
        el.utf8String = "";
        assert(el.utf8String == "");
        el.utf8String = "henlo borthers";
        assert(el.utf8String == "henlo borthers");

        // Assert that accessor does not mutate state
        assert(el.utf8String == el.utf8String);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        string test = "HENLO";
        Element el = new Element();
        el.utf8String = test;
        el.value[4] = 0x88u;
        assert(test[4] == 'O');
    }

    ///
    public alias roid = relativeObjectIdentifier;
    ///
    public alias relativeOID = relativeObjectIdentifier;
    /// Decodes a portion of an Object Identifier
    abstract public @property
    OIDNode[] relativeObjectIdentifier() const;

    /// Encodes a porition of an Object Identifier
    abstract public @property
    void relativeObjectIdentifier(in OIDNode[] value);

    @system
    unittest
    {
        Element el = new Element();
        OIDNode[] input = [ OIDNode(3), OIDNode(5), OIDNode(7), OIDNode(9) ];
        el.roid = input;
        OIDNode[] output = el.roid;

        assert(input.length == output.length);
        for (ptrdiff_t i = 0; i < input.length; i++)
        {
            assert(input[i] == output[i]);
        }

        // Assert that accessor does not mutate state
        assert(el.relativeObjectIdentifier == el.relativeObjectIdentifier);
    }

    /**
        Decodes an array of elements.

        Credits:
            Thanks to StackOverflow user
            $(LINK2 https://stackoverflow.com/users/359297/biotronic, BioTronic)
            for teaching me how to create the abstract method that uses the
            child class as a template.
    */
    abstract public @property
    Element[] sequence() const;

    /**
        Encodes an array of elements.

        Credits:
            Thanks to StackOverflow user
            $(LINK2 https://stackoverflow.com/users/359297/biotronic, BioTronic)
            for teaching me how to create the abstract method that uses the
            child class as a template.
    */
    abstract public @property
    void sequence(in Element[] value);

    /**
        Decodes an array of elements.

        Credits:
            Thanks to StackOverflow user
            $(LINK2 https://stackoverflow.com/users/359297/biotronic, BioTronic)
            for teaching me how to create the abstract method that uses the
            child class as a template.
    */
    abstract public @property
    Element[] set() const;

    /**
        Encodes an array of elements.

        Credits:
            Thanks to StackOverflow user
            $(LINK2 https://stackoverflow.com/users/359297/biotronic, BioTronic)
            for teaching me how to create the abstract method that uses the
            child class as a template.
    */
    abstract public @property
    void set(in Element[] value);

    /**
        Decodes a string, where the characters of the string are limited to
        0 - 9 and space.
    */
    abstract public @property
    string numericString() const;

    /**
        Encodes a string, where the characters of the string are limited to
        0 - 9 and space.
    */
    abstract public @property
    void numericString(in string value);

    @system
    unittest
    {
        Element el = new Element();
        el.numericString = "";
        assert(el.numericString == "");
        el.numericString = "1234567890";
        assert(el.numericString == "1234567890");
        el.numericString = " ";
        assert(el.numericString == " ");
        assertThrown!ASN1ValueInvalidException(el.numericString = "hey hey");
        assertThrown!ASN1ValueInvalidException(el.numericString = "12345676789A");

        // Assert that accessor does not mutate state
        assert(el.numericString == el.numericString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        string test = "12345";
        Element el = new Element();
        el.numericString = test;
        el.value[4] = 0x88u;
        assert(test[4] == '5');
    }

    /**
        Decodes a string that will only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period,
        forward slash, colon, equals, and question mark.
    */
    abstract public @property
    string printableString() const;

    /**
        Encodes a string that will only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period,
        forward slash, colon, equals, and question mark.
    */
    abstract public @property
    void printableString(in string value);

    @system
    unittest
    {
        Element el = new Element();
        el.printableString = "";
        assert(el.printableString == "");
        el.printableString = "1234567890 asdfjkl";
        assert(el.printableString == "1234567890 asdfjkl");
        el.printableString = " ";
        assert(el.printableString == " ");
        assertThrown!ASN1ValueInvalidException(el.printableString = "\t");
        assertThrown!ASN1ValueInvalidException(el.printableString = "\n");
        assertThrown!ASN1ValueInvalidException(el.printableString = "\0");
        assertThrown!ASN1ValueInvalidException(el.printableString = "\v");
        assertThrown!ASN1ValueInvalidException(el.printableString = "\b");
        assertThrown!ASN1ValueInvalidException(el.printableString = "\r");
        assertThrown!ASN1ValueInvalidException(el.printableString = "\x13");

        // Assert that accessor does not mutate state
        assert(el.printableString == el.printableString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        string test = "HENLO";
        Element el = new Element();
        el.printableString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 'O');
    }

    ///
    public alias t61String = teletexString;
    /// Decodes bytes representing the T.61 Character Set
    abstract public @property
    ubyte[] teletexString() const;

    /// Encodes bytes representing the T.61 Character Set
    abstract public @property
    void teletexString(in ubyte[] value);

    @system
    unittest
    {
        Element el = new Element();
        el.teletexString = [];
        assert(el.teletexString == []);
        el.teletexString = [ 0x01u, 0x03u, 0x05u, 0x07u, 0x09u ];
        assert(el.teletexString == [ 0x01u, 0x03u, 0x05u, 0x07u, 0x09u ]);

        // Assert that accessor does not mutate state
        assert(el.teletexString == el.teletexString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        ubyte[] test = [ 0x05u, 0x02u, 0xFFu, 0x00u, 0x6Au ];
        Element el = new Element();
        el.teletexString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 0x6Au);
    }

    // Test that mutating a large value does not mutate an external reference.
    @system
    unittest
    {
        ubyte[] test;
        test.length = 10000u;
        Element el = new Element();
        el.teletexString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 0x00u);
    }

    abstract public @property
    ubyte[] videotexString() const;

    abstract public @property
    void videotexString(in ubyte[] value);

    @system
    unittest
    {
        Element el = new Element();
        el.videotexString = [];
        assert(el.videotexString == []);
        el.videotexString = [ 0x01u, 0x03u, 0x05u, 0x07u, 0x09u ];
        assert(el.videotexString == [ 0x01u, 0x03u, 0x05u, 0x07u, 0x09u ]);

        // Assert that accessor does not mutate state
        assert(el.videotexString == el.videotexString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        ubyte[] test = [ 0x05u, 0x02u, 0xFFu, 0x00u, 0x6Au ];
        Element el = new Element();
        el.videotexString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 0x6Au);
    }

    // Test that mutating a large value does not mutate an external reference.
    @system
    unittest
    {
        ubyte[] test;
        test.length = 10000u;
        Element el = new Element();
        el.videotexString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 0x00u);
    }

    ///
    public alias ia5String = internationalAlphabetNumber5String;
    /// Decodes a string of ASCII characters
    abstract public @property
    string internationalAlphabetNumber5String() const;

    /// Encodes a string of ASCII characters
    abstract public @property
    void internationalAlphabetNumber5String(in string value);

    @system
    unittest
    {
        Element el = new Element();
        el.ia5String = "";
        assert(el.ia5String == "");
        el.ia5String = "Nitro dubs & T-Rix";
        assert(el.ia5String == "Nitro dubs & T-Rix");
        assertThrown!ASN1ValueInvalidException(el.ia5String = "Nitro dubs \xD7 T-Rix");

        // Assert that accessor does not mutate state
        assert(el.ia5String == el.ia5String);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        string test = "HENLO";
        Element el = new Element();
        el.ia5String = test;
        el.value[4] = 0x88u;
        assert(test[4] == 'O');
    }

    ///
    public alias utc = coordinatedUniversalTime;
    ///
    public alias utcTime = coordinatedUniversalTime;
    /// Decodes a DateTime
    abstract public @property
    DateTime coordinatedUniversalTime() const;

    /// Encodes a DateTime
    abstract public @property
    void coordinatedUniversalTime(in DateTime value);

    @system
    unittest
    {
        Element el = new Element();
        el.utcTime = DateTime(2017, 10, 3);
        assert(el.utcTime == DateTime(2017, 10, 3));

        // Assert that accessor does not mutate state
        assert(el.utcTime == el.utcTime);
    }

    /// Decodes a DateTime
    abstract public @property
    DateTime generalizedTime() const;

    /// Encodes a DateTime
    abstract public @property
    void generalizedTime(in DateTime value);

    @system
    unittest
    {
        Element el = new Element();
        el.generalizedTime = DateTime(2017, 10, 3);
        assert(el.generalizedTime == DateTime(2017, 10, 3));

        // Assert that accessor does not mutate state
        assert(el.generalizedTime == el.generalizedTime);
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

    */
    deprecated
    abstract public @property
    string graphicString() const;

    /**
        Encodes an ASCII string that contains only characters between and
        including 0x20 and 0x75.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022,
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

    */
    deprecated
    abstract public @property
    void graphicString(in string value);

    @system
    unittest
    {
        Element el = new Element();
        el.graphicString = "";
        assert(el.graphicString == "");
        el.graphicString = "Nitro dubs & T-Rix";
        assert(el.graphicString == "Nitro dubs & T-Rix");
        el.graphicString = " ";
        assert(el.graphicString == " ");
        assertThrown!ASN1ValueInvalidException(el.graphicString = "\xD7");
        assertThrown!ASN1ValueInvalidException(el.graphicString = "\t");
        assertThrown!ASN1ValueInvalidException(el.graphicString = "\r");
        assertThrown!ASN1ValueInvalidException(el.graphicString = "\n");
        assertThrown!ASN1ValueInvalidException(el.graphicString = "\b");
        assertThrown!ASN1ValueInvalidException(el.graphicString = "\v");
        assertThrown!ASN1ValueInvalidException(el.graphicString = "\f");
        assertThrown!ASN1ValueInvalidException(el.graphicString = "\0");

        // Assert that accessor does not mutate state
        assert(el.graphicString == el.graphicString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        string test = "HENLO";
        Element el = new Element();
        el.graphicString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 'O');
    }

    ///
    public alias iso646String = visibleString;
    /**
        Decodes a string that only contains characters between and including
        0x20 and 0x7E. (Honestly, I don't know how this differs from
        GraphicalString.)
    */
    abstract public @property
    string visibleString() const;

    /**
        Encodes a string that only contains characters between and including
        0x20 and 0x7E. (Honestly, I don't know how this differs from
        GraphicalString.)
    */
    abstract public @property
    void visibleString(in string value);

    @system
    unittest
    {
        Element el = new Element();
        el.visibleString = "";
        assert(el.visibleString == "");
        el.visibleString = "hey hey";
        assert(el.visibleString == "hey hey");
        el.visibleString = " ";
        assert(el.visibleString == " ");
        assertThrown!ASN1ValueInvalidException(el.visibleString = "\xD7");
        assertThrown!ASN1ValueInvalidException(el.visibleString = "\t");
        assertThrown!ASN1ValueInvalidException(el.visibleString = "\r");
        assertThrown!ASN1ValueInvalidException(el.visibleString = "\n");
        assertThrown!ASN1ValueInvalidException(el.visibleString = "\b");
        assertThrown!ASN1ValueInvalidException(el.visibleString = "\v");
        assertThrown!ASN1ValueInvalidException(el.visibleString = "\f");
        assertThrown!ASN1ValueInvalidException(el.visibleString = "\0");

        // Assert that accessor does not mutate state
        assert(el.visibleString == el.visibleString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        string test = "HENLO";
        Element el = new Element();
        el.visibleString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 'O');
    }

    /// Decodes a string containing only ASCII characters.
    deprecated
    abstract public @property
    string generalString();

    /// Encodes a string containing only ASCII characters.
    deprecated
    abstract public @property
    void generalString(in string value);

    @system
    unittest
    {
        Element el = new Element();
        el.generalString = "";
        assert(el.generalString == "");
        el.generalString = "foin-ass sweatpants from BUCCI \0\n\t\b\v\r\f";
        assert(el.generalString == "foin-ass sweatpants from BUCCI \0\n\t\b\v\r\f");
        assertThrown!ASN1ValueInvalidException(el.generalString = "\xF5");

        // Assert that accessor does not mutate state
        assert(el.generalString == el.generalString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        string test = "HENLO";
        Element el = new Element();
        el.generalString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 'O');
    }

    /// Decodes a string of UTF-32 characters
    abstract public @property
    dstring universalString() const;

    /// Encodes a string of UTF-32 characters
    abstract public @property
    void universalString(in dstring value);

    @system
    unittest
    {
        Element el = new Element();
        el.universalString = ""d;
        assert(el.universalString == ""d);
        el.universalString = "abcd"d;
        assert(el.universalString == "abcd"d);

        // Assert that accessor does not mutate state
        assert(el.universalString == el.universalString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        dstring test = "HENLO"d;
        Element el = new Element();
        el.universalString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 'O');
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
    */
    abstract public @property
    CharacterString characterString() const;

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
    abstract public @property
    void characterString(in CharacterString value);

    @system
    unittest
    {
        ASN1Syntaxes syn = ASN1Syntaxes();
        syn.abstractSyntax = new OID(1, 3, 6, 4, 1, 256, 7);
        syn.transferSyntax = new OID(1, 3, 6, 4, 1, 256, 8);

        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.syntaxes = syn;

        CharacterString input = CharacterString();
        input.identification = id;
        input.stringValue = [ 'H', 'E', 'L', 'N', 'O' ];

        Element el = new Element();
        el.characterString = input;

        // TODO: Test el.value

        CharacterString output = el.characterString;
        assert(output.identification.syntaxes.abstractSyntax == new OID(1, 3, 6, 4, 1, 256, 7));
        assert(output.identification.syntaxes.transferSyntax == new OID(1, 3, 6, 4, 1, 256, 8));
        assert(output.stringValue == [ 'H', 'E', 'L', 'N', 'O' ]);
    }

    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.syntax = new OID(1, 3, 6, 4, 1, 256, 39);

        CharacterString input = CharacterString();
        input.identification = id;
        input.stringValue = [ 'H', 'E', 'N', 'L', 'O' ];

        Element el = new Element();
        el.characterString = input;
        CharacterString output = el.characterString;
        assert(output.identification.syntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.stringValue == [ 'H', 'E', 'N', 'L', 'O' ]);
    }

    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.transferSyntax = new OID(1, 3, 6, 4, 1, 256, 39);

        CharacterString input = CharacterString();
        input.identification = id;
        input.stringValue = [ 'H', 'E', 'N', 'L', 'O' ];

        Element el = new Element();
        el.characterString = input;
        CharacterString output = el.characterString;
        assert(output.identification.transferSyntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.stringValue == [ 'H', 'E', 'N', 'L', 'O' ]);
    }

    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.fixed = true;

        CharacterString input = CharacterString();
        input.identification = id;
        input.stringValue = [ 'H', 'E', 'N', 'L', 'O' ];

        Element el = new Element();
        el.characterString = input;
        CharacterString output = el.characterString;
        assert(output.identification.fixed == true);
        assert(output.stringValue == [ 'H', 'E', 'N', 'L', 'O' ]);

        // Assert that accessor does not mutate state
        assert(el.characterString == el.characterString);
    }

    ///
    public alias bmpString = basicMultilingualPlaneString;
    /// Decodes a string of UTF-16 characters
    abstract public @property
    wstring basicMultilingualPlaneString() const;

    /// Encodes a string of UTF-16 characters
    abstract public @property
    void basicMultilingualPlaneString(in wstring value);

    @system
    unittest
    {
        Element el = new Element();
        el.bmpString = ""w;
        assert(el.bmpString == ""w);
        el.bmpString = "abcd"w;
        assert(el.bmpString == "abcd"w);

        // Assert that accessor does not mutate state
        assert(el.bmpString == el.bmpString);
    }

    // Test that mutating the value does not mutate an external reference.
    @system
    unittest
    {
        wstring test = "HENLO"w;
        Element el = new Element();
        el.bmpString = test;
        el.value[4] = 0x88u;
        assert(test[4] == 'O');
    }

}