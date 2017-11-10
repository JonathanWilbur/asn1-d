/**
    Distinguished Encoding Rules (DER) is a standard for encoding ASN.1 data.
    DER is often used for cryptgraphically-signed data, such as X.509
    certificates, because DER's defining feature is that there is only one way
    to encode each data type, which means that two encodings of the same data
    could not have different cryptographic signatures. For this reason, DER
    is generally regarded as the most secure encoding standard for ASN.1.
    Like Basic Encoding Rules (BER), Canonical Encoding Rules (CER), and 
    Packed Encoding Rules (PER), Distinguished Encoding Rules is a 
    specification created by the 
    $(LINK2 http://www.itu.int/en/pages/default.aspx, 
        International Telecommunications Union),
    and specified in 
    $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

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
module codecs.der;
public import codec;
public import types.identification;

///
public alias DERElement = DistinguishedEncodingRulesElement;
/**
    The unit of encoding and decoding for Distinguished Encoding Rules DER.
    
    There are three parts to an encoded DER Value:

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
    DERElement dv = new DERElement();
    dv.type = 0x02u; // "2" means this is an INTEGER
    dv.integer = 1433; // Now the data is encoded.
    transmit(cast(ubyte[]) dv); // transmit() is a made-up function.
    ---

    And this is what decoding looks like:

    ---
    ubyte[] data = receive(); // receive() is a made-up function.
    DERElement dv2 = new DERElement(data);

    long x;
    if (dv.type == 0x02u) // it is an INTEGER
    {
        x = dv.integer;
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
class DistinguishedEncodingRulesElement : ASN1Element!DERElement
{
    // Constants used to save CPU cycles
    private immutable real maxUintAsReal = cast(real) uint.max; // Saves CPU cycles in realType()
    private immutable real maxLongAsReal = cast(real) long.max; // Saves CPU cycles in realType()
    private immutable real logBaseTwoOfTen = log2(10.0); // Saves CPU cycles in realType()

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
        "encoded using Distinguished Encoding Rules, Canonical Encoding Rules, or " ~
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

    // Settings

    ///
    public
    enum LengthEncodingPreference : ubyte
    {
        definite,
        indefinite
    }

    /// The base of encoded REALs. May be 2, 8, 10, or 16.
    static public ASN1RealEncodingBase realEncodingBase = ASN1RealEncodingBase.base2;

    /** 
        Returns the tag class of the element. Though you could directly get the
        class yourself, you should still use this property instead; not doing
        so is a good way to introduce bugs into your program.

        Returns: the tag class of the element.
    */
    final public @property nothrow @safe
    ASN1TagClass typeClass() const
    {
        switch (this.type & 0b1100_0000u)
        {
            case (0b0000_0000u):
            {
                return ASN1TagClass.universal;
            }
            case (0b0100_0000u):
            {
                return ASN1TagClass.application;
            }
            case (0b1000_0000u):
            {
                return ASN1TagClass.contextSpecific;
            }
            case (0b1100_0000u):
            {
                return ASN1TagClass.privatelyDefined;
            }
            default:
            {
                assert(0, "Impossible tag class appeared!");
            }
        }
    }

    /** 
        Sets the tag class of the element. Though you could directly set the
        class yourself, you should still use this property instead; not doing
        so is a good way to introduce bugs into your program.
    */
    final public @property nothrow @safe
    void typeClass(ASN1TagClass value)
    {
        this.type |= cast(ubyte) value;
    }

    /** 
        Returns the construction of the element. Though you could directly get 
        the construction yourself, you should still use this property instead; 
        not doing so is a good way to introduce bugs into your program.

        Returns: the tag class of the element.
    */
    final public @property nothrow @safe
    ASN1Construction typeConstruction() const
    {
        switch (this.type & 0b0010_0000u)
        {
            case (0b0000_0000u):
            {
                return ASN1Construction.primitive;
            }
            case (0b0010_0000u):
            {
                return ASN1Construction.constructed;
            }
            default:
            {
                assert(0, "Impossible tag class appeared!");
            }
        }
    }

    /** 
        Sets the construction of the element. Though you could directly set 
        the construction yourself, you should still use this property instead; 
        not doing so is a good way to introduce bugs into your program.
    */
    final public @property nothrow @safe
    void typeConstruction(ASN1Construction value)
    {
        this.type |= cast(ubyte) value;
    }

    /** 
        Returns the type number of the element. Though you could directly get 
        the number yourself, you should still use this property instead; 
        not doing so is a good way to introduce bugs into your program.

        Returns: the type number associated with this element.
    */
    final public @property nothrow @safe
    T typeNumber(T)() const
    if (isIntegral!T && isUnsigned!T)
    {
        return cast(T) (this.type & 0b0001_1111u);
    }

    /** 
        Sets the type number of the element. Though you could directly set 
        the number yourself, you should still use this property instead; 
        not doing so is a good way to introduce bugs into your program.
    */
    final public @property @safe
    void typeNumber(T)(T value)
    if (isIntegral!T && isUnsigned!T)
    {
        if (value > 31u)
            throw new ASN1CodecException
            (
                "This exception was thrown because you attempted to assign a " ~
                "value greater than 31 to the type number of a BER-encoded " ~
                "ASN.1 element. Since the type tag reserves only five bits " ~
                "for encoding the type number, the valid range of type numbers " ~
                "is strictly between 0 and 31, inclusively."
            );
        
        this.type |= ((cast(ubyte) value) & 0b0001_1111u);
    }

    /// The type tag of this element
    public ubyte type;

    /// The length of the value in octets
    final public @property @safe nothrow
    size_t length() const
    {
        return this.value.length;
    }

    /// The octets of the encoded value.
    public ubyte[] value;

    /**
        Decodes a boolean.
        
        Any non-zero value will be interpreted as TRUE. Only zero will be
        interpreted as FALSE.
        
        Returns: a boolean
        Throws:
            ASN1ValueSizeException = if the encoded value is anything other
                than exactly 1 byte in size.
            ASN1ValueInvalidException = if the encoded byte is not 0xFF or 0x00
    */
    override public @property @safe
    bool boolean() const
    {
        if (this.value.length != 1u)
            throw new ASN1ValueSizeException
            (
                "In Distinguished Encoding Rules, a BOOLEAN must be encoded on exactly " ~
                "one byte (in addition to the type and length bytes, of " ~
                "course). This exception was thrown because you attempted to " ~
                "decode a BOOLEAN from an element that had either zero or more " ~
                "than one bytes as the encoded value. " ~ notWhatYouMeantText ~ 
                forMoreInformationText ~ debugInformationText ~ reportBugsText
            );

        if (this.value[0] == 0xFFu)
        {
            return true;
        }
        else if (this.value[0] == 0x00u)
        {
            return false;
        }
        else
        {
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode a BOOLEAN " ~
                "that was encoded on a byte that was not 0xFF or 0x00 using the DER " ~
                "codec. Any encoding of a boolean other than 0xFF (true) or 0x00 " ~
                "(false) is restricted by the DER codec. " ~ notWhatYouMeantText ~
                forMoreInformationText ~ debugInformationText ~ reportBugsText
            );
        }
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
        DERElement dv = new DERElement();
        dv.value = [ 0xFFu ];
        assert(dv.boolean == true);
        dv.value = [ 0x00u ];
        assert(dv.boolean == false);
        dv.value = [ 0x01u, 0x00u ];
        assertThrown!ASN1ValueSizeException(dv.boolean);
        dv.value = [];
        assertThrown!ASN1ValueSizeException(dv.boolean);
        dv.value = [ 0x01u ];
        assertThrown!ASN1ValueInvalidException(dv.boolean);
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
    T integer(T)() const
    if (isIntegral!T && isSigned!T)
    {
        /* NOTE:
            this.value must be duplicated; if it is not, the reverse() operation
            below reverses this.value, which persists until the next decode!
        */
        ubyte[] value = this.value.dup;
        if (value.length > T.sizeof)
            throw new ASN1ValueTooBigException
            (
                "This exception was thrown because you attempted to decode an " ~
                "INTEGER that was just too large to decode to any signed " ~
                "integral data type. The largest INTEGER that can be decoded " ~
                "is eight bytes, which can only be decoded to a long. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        // REVIEW: Does this need to apply to BER as well?
        /* NOTE:
            Because the DER INTEGER is stored in two's complement form, you 
            can't just apppend 0x00u to the big end of it until it is as long
            as T in bytes, then cast to T. Instead, you have to first determine
            if the encoded integer is negative or positive. If it is negative,
            then you actually want to append 0xFFu to the big end until it is
            as big as T, so you get the two's complement form of whatever T
            you choose.

            The line immediately below this determines whether the padding byte
            should be 0xFF or 0x00 based on the most significant bit of the 
            most significant byte (which, since DER encodes big-endian, will
            always be the first byte). If set (1), the number is negative, and
            hence, the padding byte should be 0xFF. If not, it is positive,
            and the padding byte should be 0x00.
        */
        ubyte paddingByte = ((this.value[0] & 0x80u) ? 0xFFu : 0x00u);
        while (value.length < T.sizeof)
            value = (paddingByte ~ value);
        version (LittleEndian) reverse(value);
        assert(value.length == T.sizeof);
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
        version (LittleEndian) reverse(ub);
    
        /*
            An INTEGER must be encoded on the fewest number of bytes than can
            encode it. The loops below identify how many bytes can be 
            truncated from the start of the INTEGER, with one loop for positive
            and another loop for negative numbers. 
        */
        ptrdiff_t startOfNonPadding = 0;
        if (value >= 0)
        {
            for (ptrdiff_t i = 0; i < ub.length-1; i++)
            {
                if (ub[i] == 0x00 && ((ub[i+1] & 0x80) == 0x00)) 
                    startOfNonPadding++;
            }
        }
        else
        {
            for (ptrdiff_t i = 0; i < ub.length-1; i++)
            {
                if (ub[i] == 0xFF && ((ub[i+1] & 0x80) == 0x80)) 
                    startOfNonPadding++;
            }
        }

        this.value = ub[startOfNonPadding .. $];
    }

    /**
        Decodes an array of $(D bool)s representing a string of bits.

        In Distinguished Encoding Rules, the first byte is an unsigned
        integral byte indicating the number of unused bits at the end of
        the BIT STRING. The unused bits must be zeroed.

        Returns: an array of booleans.
        Throws:
            ASN1ValueInvalidException = if the first byte has a value greater
                than seven.
    */
    override public @property
    bool[] bitString() const
    {
        if (this.value.length == 0u)
            throw new ASN1ValueTooSmallException
            (
                "This exception was thrown because you attempted to decode a " ~
                "BIT STRING that was encoded on zero bytes. A BIT STRING " ~
                "requires at least one byte to encode the length. " 
                ~ notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        if (this.value[0] > 0x07u)
            throw new ASN1ValueInvalidException
            (
                "In Distinguished Encoding Rules, the first byte of the encoded " ~
                "binary value (after the type and length bytes, of course) " ~ 
                "is used to indicate how many unused bits there are at the " ~
                "end of the BIT STRING. Since everything is encoded in bytes " ~
                "in Distinguished Encoding Rules, but a BIT STRING may not " ~
                "necessarily encode a number of bits, divisible by eight " ~
                "there may be bits at the end of the BIT STRING that will " ~
                "need to be identified as padding instead of meaningful data." ~
                "Since a byte is eight bits, the largest number that the " ~
                "first byte should encode is 7, since, if you have eight " ~
                "unused bits or more, you may as well truncate an entire " ~
                "byte from the encoded data. This exception was thrown because " ~
                "you attempted to decode a BIT STRING whose first byte " ~
                "had a value greater than seven. The value was: " ~ 
                text(this.value[0]) ~ ". " ~ notWhatYouMeantText ~ 
                forMoreInformationText ~ debugInformationText ~ reportBugsText
            );
        
        bool[] ret;
        for (ptrdiff_t i = 1; i < this.value.length; i++)
        {
            ret ~= [
                (this.value[i] & 0b1000_0000u ? true : false),
                (this.value[i] & 0b0100_0000u ? true : false),
                (this.value[i] & 0b0010_0000u ? true : false),
                (this.value[i] & 0b0001_0000u ? true : false),
                (this.value[i] & 0b0000_1000u ? true : false),
                (this.value[i] & 0b0000_0100u ? true : false),
                (this.value[i] & 0b0000_0010u ? true : false),
                (this.value[i] & 0b0000_0001u ? true : false)
            ];
        }
        ret.length -= this.value[0];
        return ret;
    }

    /**
        Encodes an array of $(D bool)s representing a string of bits.

        In Distinguished Encoding Rules, the first byte is an unsigned
        integral byte indicating the number of unused bits at the end of
        the BIT STRING. The unused bits must be zeroed.
    */
    override public @property
    void bitString(bool[] value)
    {
        if (value == []) // FIXME: Or, if there are no 1-bits
        {
            this.value = [ 0x00u ];
            return;
        }
        // REVIEW: I feel like there is a better way to do this...
        this.value = [ cast(ubyte) (8u - (value.length % 8u)) ];
        if (this.value[0] == 0x08u) this.value[0] = 0x00u;

        ptrdiff_t i = 0;
        while (i < value.length)
        {
            if (!(i % 8u)) this.value ~= 0x00u;
            this.value[$-1] |= ((value[i] ? 0b1000_0000u : 0b0000_0000u) >> (i % 8u));
            i++;
        }
    }

    /**
        Decodes an OCTET STRING into an unsigned byte array.

        Returns: an unsigned byte array.
    */
    override public @property @safe
    ubyte[] octetString() const
    {
        return this.value.dup;
    }

    /**
        Encodes an OCTET STRING from an unsigned byte array.
    */
    override public @property @safe
    void octetString(ubyte[] value)
    {
        this.value = value;
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

        Throws:
            ASN1ValueTooSmallException = if an attempt is made to decode
                an Object Identifier from zero bytes.
            ASN1ValueTooBigException = if a single OID number is too big to 
                decode to a size_t.
        Standards:
            $(LINK2 http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660)
    */
    override public @property @system
    OID objectIdentifier() const
    out (value)
    {
        assert(value.length > 2u);
    }
    body
    {
        if (this.value.length == 0u)
            throw new ASN1ValueTooSmallException
            (
                "This exception was thrown because you attempted to decode " ~
                "an OBJECT IDENTIFIER from no bytes. An OBJECT IDENTIFIER " ~
                "must be encoded on at least one byte. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        ubyte[][] components;
        size_t[] numbers = [ (this.value[0] / 0x28u), (this.value[0] % 0x28u) ];
        Appender!(OIDNode[]) nodes = appender!(OIDNode[])();
        
        // Breaks bytes into groups, where each group encodes one OID number.
        ptrdiff_t lastTerminator = 1;
        for (ptrdiff_t i = 1; i < this.length; i++)
        {
            if (!(this.value[i] & 0x80u))
            {
                components ~= cast(ubyte[]) this.value[lastTerminator .. i+1];
                lastTerminator = i+1;
            }
        }

        // Converts each group of bytes to a number.
        foreach (component; components)
        {
            if (component.length > (size_t.sizeof * 2u))
                throw new ASN1ValueTooBigException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an OBJECT IDENTIFIER that encoded a number on more than " ~
                    "size_t*2 bytes (16 on 64-bit, 8 on 32-bit). " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            numbers ~= 0u;
            for (ptrdiff_t i = 0; i < component.length; i++)
            {
                numbers[$-1] <<= 7;
                numbers[$-1] |= cast(size_t) (component[i] & 0x7Fu);
            }
        }
        
        // Constructs the array of OIDNodes from the array of numbers.
        foreach (number; numbers)
        {
            nodes.put(OIDNode(number));
        }

        return new OID(cast(immutable OIDNode[]) nodes.data);
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
    override public @property @system
    void objectIdentifier(OID value)
    in
    {
        assert(value.length > 2u);
        assert(value.numericArray[0] <= 2u);
        assert(value.numericArray[1] <= 39u);
    }
    body
    {
        size_t[] numbers = value.numericArray();
        this.value = [ cast(ubyte) (numbers[0] * 40u + numbers[1]) ];
        if (numbers.length > 2)
        {
            foreach (number; numbers[2 .. $])
            {
                ubyte[] encodedOIDComponent;
                if (number < 128u)
                {
                    this.value ~= cast(ubyte) number;
                    continue;
                }
                while (number != 0)
                {
                    ubyte[] compbytes;
                    compbytes.length = size_t.sizeof;
                    *cast(size_t *) compbytes.ptr = number;
                    if ((compbytes[0] & 0x80u) == 0) compbytes[0] |= 0x80u;
                    encodedOIDComponent = compbytes[0] ~ encodedOIDComponent;
                    number >>= 7;
                }
                encodedOIDComponent[$-1] &= 0x7Fu;
                this.value ~= encodedOIDComponent;
            }
        }
    }

    /**
        Decodes an ObjectDescriptor, which is a string consisting of only
        graphical characters. In fact, ObjectDescriptor is actually implicitly
        just a GraphicString! The formal specification for an ObjectDescriptor
        is:

        $(I ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        GraphicString is just 0x20 to 0x7E, therefore ObjectDescriptor is just
        0x20 to 0x7E.

        Citations:
            Dubuisson, Olivier. “Character String Types.” ASN.1: 
                Communication between Heterogeneous Systems, Morgan 
                Kaufmann, 2001, pp. 175-178.
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

        Returns: a string.
        Throws:
            ASN1ValueInvalidException = if the encoded value contains any bytes
                outside of 0x20 to 0x7E.
    */
    override public @property @system
    string objectDescriptor() const
    {
        foreach (character; this.value)
        {
            if ((!character.isGraphical) && (character != ' '))
            {
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "an ObjectDescriptor that contained a character that " ~
                    "is not graphical (a character whose ASCII encoding " ~
                    "is outside of the range 0x20 to 0x7E). The encoding of the offending " ~
                    "character is '" ~ text(cast(uint) character) ~ "'. " ~ notWhatYouMeantText ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
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

        Citations:
            Dubuisson, Olivier. “Character String Types.” ASN.1: 
                Communication between Heterogeneous Systems, Morgan 
                Kaufmann, 2001, pp. 175-178.
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

        Throws:
            ASN1ValueInvalidException = if the string value contains any
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
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "an ObjectDescriptor that contained a character that " ~
                    "is not graphical (a character whose ASCII encoding " ~
                    "is outside of the range 0x20 to 0x7E). The encoding of the offending " ~
                    "character is '" ~ text(cast(uint) character) ~ "'. " ~ notWhatYouMeantText ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
            }
        }
        this.value = cast(ubyte[]) value;
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

        Returns: an External, defined in types.universal.external.
        Throws:
            ASN1SizeException = if encoded EmbeddedPDV has too few or too many
                elements, or if syntaxes or context-negotiation element has
                too few or too many elements.
            ASN1ValueTooBigException = if encoded INTEGER is too large to decode.
            ASN1ValueInvalidException = if encoded ObjectDescriptor contains
                invalid characters.
            ASN1InvalidIndexException = if encoded value selects a choice for 
                identification or uses an unspecified index for an element in
                syntaxes or context-negotiation, or if an unspecified element
                of EMBEDDED PDV itself is referenced by an out-of-range 
                context-specific index. (See $(D_INLINECODE ASN1InvalidIndexException).)
    */
    override public @property @system
    External external() const
    {
        DERElement[] dvs = this.sequence;
        if (dvs.length < 2 || dvs.length > 3)
            throw new ASN1ValueSizeException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EXTERNAL that contained too many or too few elements. " ~
                "An EXTERNAL should have either two or three elements: " ~
                "identification, an optional data-value-descriptor, and " ~
                "a data-value, in that order. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        External ext = External();
        if (dvs[0].type == 0x80u)
        {
            ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();
            DERElement identificationElement = new DERElement(dvs[0].value);
            /* NOTE:
                'syntax' is the only permitted CHOICE for EXTERNAL's identification, 
                when using Distinguished Encoding Rules (DER).
            */
            if (identificationElement.type == 0x80u) 
            {
                identification.syntax = identificationElement.objectIdentifier;
            }
            else
            {
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an EXTERNAL whose CHOICE of identification was something " ~
                    "other than `syntax`. When using Distinguished Encoding " ~
                    "Rules (DER), `syntax` is the only permitted CHOICE of " ~
                    "identification. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );
            }
            ext.identification = identification;
        }
        else
        {
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because, you attempted to decode " ~
                "an EXTERNAL whose elements were not exactly in the order " ~
                "they appear in the specification. Distinguished Encoding " ~
                "Rules (DER) specify that the encoded elements of any " ~
                "constructed type must appear in the order of their specification, " ~
                "which, in the case of EXTERNAL, means that identification " ~
                "must appear first, then data-value. The problem in your case " ~
                "is that the first encoded element was not identification, as " ~
                "indicated by a context-specific type tag of 0x80. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );
        }

        if (dvs[1].type == 0x81u) // Next tag is the data-value-descriptor
        {
            ext.dataValueDescriptor = dvs[1].objectDescriptor;
        }
        else if (dvs[1].type == 0x82u) // Next tag is the data-value-descriptor
        {
            ext.dataValue = dvs[1].octetString;
            return ext;
        }
        else
        {
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because, you attempted to decode " ~
                "an EXTERNAL whose elements were not exactly in the order " ~
                "they appear in the specification, or entirely omitted the " ~
                " mandatory data-value field, as indicated by a context-" ~
                "specific type tag of 0x82. Distinguished Encoding " ~
                "Rules (DER) specify that the encoded elements of any " ~
                "constructed type must appear in the order of their specification, " ~
                "which, in the case of EXTERNAL, means that identification " ~
                "must appear first, then the optional data-value descriptor, " ~
                "then the data-value. The problem in your case " ~
                "is that the second encoded element was not the data-value-" ~
                "descriptor or a data-value, as would be indicated by a context-" ~
                "specific type tag of either 0x81 or 0x82 respectively. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );
        }

        if (dvs[2].type == 0x82u)
        {
            ext.dataValue = dvs[2].octetString;
            return ext;
        }
        else
        {
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because, you attempted to decode " ~
                "an EXTERNAL whose last element was not the data-value field, " ~ 
                "as indicated by a context-specific type tag of 0x82. " ~
                "Distinguished Encoding Rules (DER) specify that the encoded " ~
                "elements of any constructed type must appear in the order of " ~
                "their specification, which, in the case of EXTERNAL, means that " ~
                "identification must appear first, then the optional data-value " ~
                "descriptor, then the data-value. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );
        }
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
            ASN1ValueInvalidException = if encoded ObjectDescriptor contains
                invalid characters.
    */
    override public @property @system
    void external(External value)
    {
        DERElement identification = new DERElement();
        identification.type = 0x80u; // CHOICE is EXPLICIT, even with automatic tagging.

        DERElement identificationValue = new DERElement();
        if (value.identification.syntax.isNull)
        {
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to encode " ~
                "an EXTERNAL that used a CHOICE of identification other than " ~
                "syntax. Distinguished Encoding Rules (DER) requires that " ~
                "EXTERNALs may only use `syntax` as their CHOICE of " ~
                "identification. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );
        }

        identificationValue.type = 0x80u;
        identificationValue.objectIdentifier = value.identification.syntax;
        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationValue;

        DERElement dataValueDescriptor = new DERElement();
        dataValueDescriptor.type = 0x81u; // Primitive ObjectDescriptor
        dataValueDescriptor.objectDescriptor = value.dataValueDescriptor;

        DERElement dataValue = new DERElement();
        dataValue.type = 0x82u;
        dataValue.octetString = value.dataValue;

        this.sequence = [ identification, dataValueDescriptor, dataValue ];
    }

    /*
        Since a DER-encoded EXTERNAL can only use the syntax field for
        the CHOICE of identification, this unit test ensures that an
        exception if thrown if an alternative identification is supplied.
    */
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        External input = External();
        input.identification = id;
        input.dataValueDescriptor = "external";
        input.dataValue = [ 0x01u, 0x02u, 0x03u, 0x04u ];

        DERElement el = new DERElement();
        assertThrown!ASN1ValueInvalidException(el.external = input);
    }

    /* REVIEW:
        I have not seen it confirmed in the specification that you can use
        base-8 or base-16 for DER-encoded REALs. It seems like that would
        be a problem, since with base-2, the expectation is that the mantissa 
        is 0 or odd. I have looked at the Dubuisson book and X.690.
    */
    /**
        Decodes a float or double. This can never decode directly to a
        real type, because of the way it works.

        This is admittedly a pretty slow function, so I would recommend
        avoiding it, if possible. Also, because it is so complex, it is
        highly likely to have bugs, so for that reason as well, I highly
        recommand against encoding or decoding REALs if you do not have
        to; try using INTEGER instead.

        For the DER-encoded REAL, a value of 0x40 means "positive infinity,"
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
            ASN1ValueInvalidException = if both bits indicating the base in the
                information byte of a binary-encoded REAL's information byte 
                are set, which would indicate an invalid base.

        Citations:
            Dubuisson, Olivier. “Distinguished Encoding Rules (DER).” ASN.1: 
            Communication between Heterogeneous Systems, Morgan Kaufmann, 
            2001, pp. 400–402.
    */
    public @property @system
    T realType(T)() const
    if (is(T == float) || is(T == double))
    {
        import std.conv : ConvException, ConvOverflowException, to;

        if (this.value.length == 0) return cast(T) 0.0;

        if (this.value == [ 0x40u ]) return T.infinity;
        if (this.value == [ 0x41u ]) return -T.infinity;

        switch (this.value[0] & 0b_1100_0000)
        {
            case (0b_0100_0000u):
            {
                return ((this.value[0] & 0b_0011_1111u) ? T.infinity : -T.infinity);
            }
            case (0b_0000_0000u): // Character Encoding
            {
                return to!(T)(cast(string) this.value[1 .. $]);
            }
            case 0b_1000_0000u, 0b_1100_0000u: // Binary Encoding
            {
                /*
                    While the mantissa is a ulong here, it must be cast to a
                    long later on, so it is important that it is less than
                    long.max.
                */
                ulong mantissa;
                long exponent; // REVIEW: Can this be a smaller data type?
                ubyte scale;
                ubyte base;

                immutable string mantissaTooBigExceptionText = 
                    "This exception was thrown because the mantissa encoded by " ~
                    "a Distinguished Encoding Rules-encoded REAL could not fit in " ~
                    "to a 64-bit signed integer (long). This might indicate that " ~
                    "what you tried to decode was not actually a REAL at all. " ~
                    "For more information, see the ASN.1 library documentation, " ~
                    "or the International Telecommuncation Union's X.690 " ~
                    "specification. ";

                // There must be at least one information byte and one exponent byte.
                if (this.length < 2)
                    throw new ASN1ValueTooSmallException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a REAL that had either zero or one bytes of data," ~
                        "which cannot encode a valid binary-encoded REAL. A " ~
                        "correctly-encoded REAL has one byte for general " ~
                        "encoding information about the REAL, and at least " ~
                        "one byte for encoding the exponent. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~ 
                        debugInformationText ~ reportBugsText
                    );

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
                            throw new ASN1ValueTooBigException(mantissaTooBigExceptionText);

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
                        if (this.length < 3u)
                            throw new ASN1ValueTooSmallException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL that had too few bytes. The first " ~
                                "byte indicated that the subsequent two bytes " ~
                                "would encode the exponent of the REAL, but " ~
                                "there were less than three bytes in the entire " ~
                                "encoded value. " ~
                                notWhatYouMeantText ~ forMoreInformationText ~ 
                                debugInformationText ~ reportBugsText
                            );

                        ubyte[] exponentBytes = this.value[1 .. 3].dup;
                        version (LittleEndian) reverse(exponentBytes);
                        exponent = cast(long) (*cast(short *) exponentBytes.ptr);

                        if (this.length - 3u > 8u)
                            throw new ASN1ValueTooBigException(mantissaTooBigExceptionText);

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
                        else version (BigEndian)
                        {
                            while (this.length - m > 0u)
                            {
                                mantissa <<= 8;
                                mantissa += this.value[m];
                                m--;
                            }
                        }
                        else
                        {
                            static assert(0, "Could not determine endianness!");
                        }

                        break;
                    }
                    case 0b00000010: // Exponent on the following three octets
                    {
                        if (this.length < 4u)
                            throw new ASN1ValueTooSmallException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL that had too few bytes. The first " ~
                                "byte indicated that the subsequent three bytes " ~
                                "would encode the exponent of the REAL, but " ~
                                "there were less than four bytes in the entire " ~
                                "encoded value. " ~
                                notWhatYouMeantText ~ forMoreInformationText ~ 
                                debugInformationText ~ reportBugsText
                            );

                        exponent = cast(long) ((*cast(int *) cast(void[4] *) &(this.value[1])) & 0x00FFFFFF);

                        if (this.length - 4u > 8u)
                            throw new ASN1ValueTooBigException(mantissaTooBigExceptionText);

                        ubyte m = 0x03u;
                        version (LittleEndian)
                        {
                            while (m < this.length)
                            {
                                mantissa <<= 8;
                                mantissa += this.value[m];
                                m++;
                            }
                        }
                        else version (BigEndian)
                        {
                            while (this.length - m > 0u)
                            {
                                mantissa <<= 8;
                                mantissa += this.value[m];
                                m--;
                            }
                        }
                        else
                        {
                            static assert(0, "Could not determine endianness!");
                        }
                        
                        break;
                    }
                    case 0b00000011: // Complicated
                    {
                        if (this.length < 2u)
                            throw new ASN1ValueTooSmallException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL that had too few bytes. The first " ~
                                "byte indicated that the subsequent byte " ~
                                "would encode the length of the exponent of the REAL, but " ~
                                "there were less than two bytes in the entire " ~
                                "encoded value. " ~
                                notWhatYouMeantText ~ forMoreInformationText ~ 
                                debugInformationText ~ reportBugsText
                            );
                        
                        ubyte exponentLength = this.value[1];

                        if (this.length < exponentLength)
                            throw new ASN1ValueTooSmallException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL that had too few bytes. The " ~
                                "first byte of the value indicated that the " ~
                                "second byte would encode the length of the " ~
                                "exponent, which would begin on the next byte " ~
                                "(the third byte). However, the encoded value " ~
                                "does not have enough bytes to encode the " ~
                                "exponent with the size indicated. " ~
                                notWhatYouMeantText ~ forMoreInformationText ~ 
                                debugInformationText ~ reportBugsText
                            );

                        if (exponentLength > 0x08u)
                            throw new ASN1ValueTooBigException
                            (
                                "This exception was thrown because you attempted" ~
                                "to decode a REAL that had an exponent that was " ~
                                "too big to decode to a floating-point type." ~
                                "Specifically, the exponent was encoded on " ~
                                "more than eight bytes. " ~
                                notWhatYouMeantText ~ forMoreInformationText ~ 
                                debugInformationText ~ reportBugsText
                            );

                        ubyte i = 0x00u;
                        while (i < exponentLength)
                        {
                            exponent <<= 8;
                            exponent += this.value[i];
                            i++;
                        }

                        if (this.length - 1u - exponentLength > 8u)
                            throw new ASN1ValueTooBigException(mantissaTooBigExceptionText);

                        ubyte m = 0x01u; // FIXME: I think this needs to be 0x01u + exponentLength;
                        version (LittleEndian)
                        {
                            while (m < this.length)
                            {
                                mantissa <<= 8;
                                mantissa += this.value[m];
                                m++;
                            }
                        }
                        else version (BigEndian)
                        {
                            while (this.length - m > 0u)
                            {
                                mantissa <<= 8;
                                mantissa += this.value[m];
                                m--;
                            }
                        }
                        else
                        {
                            static assert(0, "Could not determine endianness!");
                        }
                        break;
                    }
                    default:
                    {
                        assert(0, "Impossible binary exponent encoding on REAL type");
                    }
                }
                
                if (mantissa > long.max)
                    throw new ASN1ValueInvalidException(mantissaTooBigExceptionText);

                switch (this.value[0] & 0b_0011_0000)
                {
                    case (0b_0000_0000): // Base 2
                    {
                        base = 0x02u;
                        break;
                    }
                    case (0b_0001_0000): // Base 8
                    {
                        base = 0x08u;
                        break;
                    }
                    case (0b_0010_0000): // Base 16
                    {
                        base = 0x10u;
                        break;
                    }
                    default:
                    {
                        throw new ASN1ValueInvalidException
                        (
                            "This exception was throw because you attempted to " ~
                            "decode a REAL that had both base bits in the " ~
                            "information block set, the meaning of which is " ~
                            "not specified. " ~
                            notWhatYouMeantText ~ forMoreInformationText ~ 
                            debugInformationText ~ reportBugsText 
                        );
                    }
                }

                scale = ((this.value[0] & 0b_0000_1100u) >> 2);

                return (
                    ((this.value[0] & 0b_0100_0000u) ? -1.0 : 1.0) *
                    cast(long) mantissa * // Mantissa MUST be cast to a long
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

    /* REVIEW:
        I have not seen it confirmed in the specification that you can use
        base-8 or base-16 for DER-encoded REALs. It seems like that would
        be a problem, since with base-2, the expectation is that the mantissa 
        is 0 or odd. I have looked at the Dubuisson book and X.690.
    */
    /**
        Encodes a float or double. This can never decode directly to a
        real type, because of the way it works.

        This is admittedly a pretty slow function, so I would recommend
        avoiding it, if possible. Also, because it is so complex, it is
        highly likely to have bugs, so for that reason as well, I highly
        recommand against encoding or decoding REALs if you do not have
        to; try using INTEGER instead.

        For the DER-encoded REAL, a value of 0x40 means "positive infinity,"
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
            ASN1ValueInvalidException = if an attempt to encode NaN is made.
            ASN1ValueTooSmallException = if an attempt to encode would result 
                in an arithmetic underflow of a signed short.
            ASN1ValueTooBigException = if an attempt to encode would result
                in an arithmetic overflow of a signed short.

        Citations:
            Dubuisson, Olivier. “Distinguished Encoding Rules (DER).” ASN.1: 
            Communication between Heterogeneous Systems, Morgan Kaufmann, 
            2001, pp. 400–402.
    */
    public @property @system
    void realType(T)(T value)
    if (is(T == float) || is(T == double))
    {
        import std.bitmanip : DoubleRep, FloatRep;
        import std.math : floor;

        bool positive = true;
        real significand;
        ubyte scale = 2u;
        short exponent = 0;

        /**
            Because the current settings for realEncodingBase must be referenced
            repeatedly throughout this method, a private copy must be made of
            the state of this.realEncodingBase to prevent both TOCTOU 
            vulnerabilities as well as problems with concurrent programming.
        */
        ASN1RealEncodingBase base = this.realEncodingBase;

        if (value.isNaN)
        {
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to encode a " ~
                "floating-point data type with a value of NaN (not-a-number) " ~
                "as an ASN.1 REAL, but the ASN.1 REAL cannot encode NaN."
            );
        }
        else if (value == T.infinity)
        {
            this.value = [ ASN1SpecialRealValue.plusInfinity ];
            return;
        }
        else if (value == -T.infinity)
        {
            this.value = [ ASN1SpecialRealValue.minusInfinity ];
            return;
        }

        if (base == ASN1RealEncodingBase.base10)
        {
            import std.format : formattedWrite;
            Appender!string writer = appender!string();

            // FIXME: This is not exactly to specification....
            // REVIEW: Change the format strings to have the best precision for those types.
            static if (is(T == double))
            {
                writer.formattedWrite!"%.12E"(value);
            }
            static if (is(T == float))
            {
                writer.formattedWrite!"%.6E"(value);
            }

            this.value = 
                cast(ubyte[]) [ (cast(ubyte) 0u | cast(ubyte) ASN1Base10RealNumericalRepresentation.nr3) ] ~ 
                cast(ubyte[]) writer.data;
            
            return;
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
            This section here converts the base-2 floating-point type to
            either base-8 or base-16 by dividing the significand by
            2^^((log2(base)-1)*exponent), which effectively gives the
            significand the value necessary to maintain the same exponent,
            despite the underlying base having changed. Of course, doing
            so makes the significand a non-integral number, so in the
            while loop, we actually mulitply it by the base until we
            have an integral value again, decrementing the exponent by 1
            with each iteration. If the while loop detects an overflow,
            which you may get with a non-terminating fraction (such as
            10 / 3), it just reverses the last iteration, and breaks the
            loop. Yes, this may result in a loss of precision.
        */
        if (base != ASN1RealEncodingBase.base2)
        {
            if (base == ASN1RealEncodingBase.base8)
            {
                significand /= (2.0^^(2.0*exponent));
            }
            else if (base == ASN1RealEncodingBase.base16)
            {
                significand /= (2.0^^(3.0*exponent));
            }

            /*
                Sometimes the significand generated from the previous
                step can be so high that the last bit of precision is
                not a fractional bit--integral precision, in other words.
                When this happens, the long to which the significand is
                cast later on in the code is completely zeroed out. The
                loops below iteratively divide the significand by the
                base, while incrementing the exponent (so that the same
                number is represented, just with a different combination
                of significand and exponent), which gives us a significand
                that can safely be cast to a long.

                Note that the significand must be cast only to a SIGNED
                long later on, because it will be multiplied with other
                signed integral types, hence we use this loop to bring
                the floating-point significand within the range that
                can be safely cast to a signed long.
            */
            while (significand > maxLongAsReal)
            {
                significand /= base;
                if (exponent >= short.max)
                    throw new ASN1ValueTooBigException
                    (
                        "This exception was thrown because you attempted to " ~
                        "encode a floating-point type as a REAL, which " ~
                        "resulted in an exponent that was larger than a " ~
                        "signed short integer could encode. It is not your " ~
                        "fault that this exception occurred: it is a bug. " ~
                        "If you have encountered this exception, and if you " ~
                        "know specifically what number created the exception, " ~
                        "please report it on the ASN.1 library's GitHub " ~
                        "issues page: " ~ 
                        "https://github.com/JonathanWilbur/asn1-d/issues. " ~
                        "Please include your machine architecture, bit-width, " ~
                        "the exact number you tried to encode, and whether you " ~
                        "tried to encode it from a float or double."
                    );
                exponent++;
            }

            while (significand - floor(significand) != 0.0)
            {
                significand *= base;
                if (significand > maxLongAsReal)
                {
                    significand /= base;
                    break;
                }
                if (exponent <= short.min)
                    throw new ASN1ValueTooSmallException
                    (
                        "This exception was thrown because you attempted to " ~
                        "encode a floating-point type as a REAL, which " ~
                        "resulted in an exponent that was smaller than a " ~
                        "signed short integer could encode. It is not your " ~
                        "fault that this exception occurred: it is a bug. " ~
                        "If you have encountered this exception, and if you " ~
                        "know specifically what number created the exception, " ~
                        "please report it on the ASN.1 library's GitHub " ~
                        "issues page: " ~ 
                        "https://github.com/JonathanWilbur/asn1-d/issues. " ~
                        "Please include your machine architecture, bit-width, " ~
                        "the exact number you tried to encode, and whether you " ~
                        "tried to encode it from a float or double."
                    );
                exponent--;
            }
        }

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

        // If the significand is even and we're using Base-2 encoding, make it odd or 0
        // REVIEW: You might have a precision problem here, since significand is a FP type.
        if (base == ASN1RealEncodingBase.base2 && !(significand % 2) && significand != 0)
        {
            significand /= 2.0;
            exponent++;
        }

        ubyte[] exponentBytes;
        exponentBytes.length = short.sizeof;
        *cast(short *)exponentBytes.ptr = exponent;
        version (LittleEndian) reverse(exponentBytes);
        
        ubyte[] significandBytes;
        significandBytes.length = ulong.sizeof;
        *cast(ulong *)significandBytes.ptr = cast(ulong) significand;
        version (LittleEndian) reverse(significandBytes);

        ubyte baseBitMask;
        switch (base)
        {
            case (ASN1RealEncodingBase.base2):
            {
                baseBitMask = 0b0000_0000u;
                break;
            }
            case (ASN1RealEncodingBase.base8):
            {
                baseBitMask = 0b0001_0000u;
                break;
            }
            case (ASN1RealEncodingBase.base16):
            {
                baseBitMask = 0b0010_0000u;
                break;
            }
            default:
            {
                assert(0, "Impossible ASN1RealEncodingBase state appeared!");
            }
        }

        ubyte infoByte =
            0x80u | // First bit gets set for base2, base8, or base16 encoding
            (positive ? 0x00u : 0x40u) | // 1 = negative, 0 = positive
            baseBitMask | // Bitmask specifying base
            // Scale = 0
            ASN1RealExponentEncoding.following2Octets;

        this.value = (infoByte ~ exponentBytes ~ significandBytes);
    }

    // Tests of Base-8 Encoding
    @system
    unittest
    {
        DERElement.realEncodingBase = ASN1RealEncodingBase.base8;
        for (int i = -100; i < 100; i++)
        {
            // Alternating negative and positive floating point numbers exploring extreme values
            immutable float f = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            immutable double d = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            DERElement elf = new DERElement();
            DERElement eld = new DERElement();
            elf.realType!float = f;
            eld.realType!double = d;
            assert(approxEqual(elf.realType!float, f));
            assert(approxEqual(elf.realType!double, f));
            assert(approxEqual(eld.realType!float, d));
            assert(approxEqual(eld.realType!double, d));
        }
        DERElement.realEncodingBase = ASN1RealEncodingBase.base2;
    }

    // Tests of Base-16 Encoding
    @system
    unittest
    {
        DERElement.realEncodingBase = ASN1RealEncodingBase.base16;
        for (int i = -10; i < 10; i++)
        {
            // Alternating negative and positive floating point numbers exploring extreme values
            immutable float f = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            immutable double d = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            DERElement elf = new DERElement();
            DERElement eld = new DERElement();
            elf.realType!float = f;
            eld.realType!double = d;
            assert(approxEqual(elf.realType!float, f));
            assert(approxEqual(elf.realType!double, f));
            assert(approxEqual(eld.realType!float, d));
            assert(approxEqual(eld.realType!double, d));
        }
        DERElement.realEncodingBase = ASN1RealEncodingBase.base2;
    }

    // Testing Base-10 (Character-Encoded) REALs
    @system
    unittest
    {
        DERElement dv = new DERElement();
        realEncodingBase = ASN1RealEncodingBase.base10;

        // Decimal + trailing zeros are not added if not necessary.
        dv.realType!float = 22.0;
        assert(cast(string) (dv.value[1 .. $]) == "2.200000E+01");
        assert(approxEqual(dv.realType!float, 22.0));
        assert(approxEqual(dv.realType!double, 22.0));
        dv.realType!double = 22.0;
        assert(cast(string) (dv.value[1 .. $]) == "2.200000000000E+01");
        assert(approxEqual(dv.realType!float, 22.0));
        assert(approxEqual(dv.realType!double, 22.0));

        // Decimal + trailing zeros are added if necessary.
        dv.realType!float = 22.123;
        assert(cast(string) (dv.value[1 .. $]) == "2.212300E+01");
        assert(approxEqual(dv.realType!float, 22.123));
        assert(approxEqual(dv.realType!double, 22.123));
        dv.realType!double = 22.123;
        assert(cast(string) (dv.value[1 .. $]) == "2.212300000000E+01");
        assert(approxEqual(dv.realType!float, 22.123));
        assert(approxEqual(dv.realType!double, 22.123));
        
        // Negative numbers are encoded correctly.
        dv.realType!float = -22.123;
        assert(cast(string) (dv.value[1 .. $]) == "-2.212300E+01");
        assert(approxEqual(dv.realType!float, -22.123));
        assert(approxEqual(dv.realType!double, -22.123));
        dv.realType!double = -22.123;
        assert(cast(string) (dv.value[1 .. $]) == "-2.212300000000E+01");
        assert(approxEqual(dv.realType!float, -22.123));
        assert(approxEqual(dv.realType!double, -22.123));

        // Small positive numbers are encoded correctly.
        dv.realType!float = 0.123;     
        assert(cast(string) (dv.value[1 .. $]) == "1.230000E-01");
        assert(approxEqual(dv.realType!float, 0.123));
        assert(approxEqual(dv.realType!double, 0.123));
        dv.realType!double = 0.123;
        assert(cast(string) (dv.value[1 .. $]) == "1.230000000000E-01");
        assert(approxEqual(dv.realType!float, 0.123));
        assert(approxEqual(dv.realType!double, 0.123));

        // Small negative numbers are encoded correctly.
        dv.realType!float = -0.123;
        assert(cast(string) (dv.value[1 .. $]) == "-1.230000E-01");
        assert(approxEqual(dv.realType!float, -0.123));
        assert(approxEqual(dv.realType!double, -0.123));
        dv.realType!double = -0.123;
        assert(cast(string) (dv.value[1 .. $]) == "-1.230000000000E-01");
        assert(approxEqual(dv.realType!float, -0.123));
        assert(approxEqual(dv.realType!double, -0.123));
    }

    /**
        Decodes an integer from an ENUMERATED type. In DER, an ENUMERATED
        type is encoded the exact same way that an INTEGER is.

        Returns: any chosen signed integral type
        Throws:
            ASN1ValueTooBigException = if the value is too big to decode
                to a signed integral type.
    */
    public @property @system
    T enumerated(T)() const
    if (isIntegral!T && isSigned!T)
    {
        /* NOTE:
            this.value must be duplicated; if it is not, the reverse() operation
            below reverses this.value, which persists until the next decode!
        */
        ubyte[] value = this.value.dup;
        if (value.length > T.sizeof)
            throw new ASN1ValueTooBigException
            (
                "This exception was thrown because you attempted to decode an " ~
                "ENUMERATED that was just too large to decode to any signed " ~
                "integral data type. The largest ENUMERATED that can be decoded " ~
                "is eight bytes, which can only be decoded to a long. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        /* NOTE:
            Because the DER ENUMERATED is stored in two's complement form, you 
            can't just apppend 0x00u to the big end of it until it is as long
            as T in bytes, then cast to T. Instead, you have to first determine
            if the encoded integer is negative or positive. If it is negative,
            then you actually want to append 0xFFu to the big end until it is
            as big as T, so you get the two's complement form of whatever T
            you choose.

            The line immediately below this determines whether the padding byte
            should be 0xFF or 0x00 based on the most significant bit of the 
            most significant byte (which, since DER encodes big-endian, will
            always be the first byte). If set (1), the number is negative, and
            hence, the padding byte should be 0xFF. If not, it is positive,
            and the padding byte should be 0x00.
        */
        ubyte paddingByte = ((this.value[0] & 0x80u) ? 0xFFu : 0x00u);
        while (value.length < T.sizeof)
            value = (paddingByte ~ value);

        version (LittleEndian) reverse(value);
        return *cast(T *) value.ptr;
    }

    /**
        Encodes an ENUMERATED type from an integer. In DER, an ENUMERATED
        type is encoded the exact same way that an INTEGER is.
    */
    public @property @system
    void enumerated(T)(T value)
    {
        ubyte[] ub;
        ub.length = T.sizeof;
        *cast(T *)&ub[0] = value;
        version (LittleEndian) reverse(ub);
        this.value = ub[0 .. $];
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

        In Distinguished Encoding Rules, the identification CHOICE cannot be
        presentation-context-id, nor context-negotiation. Also, the elements
        must appear in the exact order of the specification. With these 
        constraints in mind, the specification effectively becomes:

        $(I
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification [0] CHOICE {
                    syntaxes [0] SEQUENCE {
                        abstract [0] OBJECT IDENTIFIER,
                        transfer [1] OBJECT IDENTIFIER },
                    syntax [1] OBJECT IDENTIFIER,
                    transfer-syntax [4] OBJECT IDENTIFIER,
                    fixed [5] NULL },
                data-value [2] OCTET STRING }
        )

        Throws:
            ASN1SizeException = if encoded EmbeddedPDV has too few or too many
                elements, or if syntaxes or context-negotiation element has
                too few or too many elements.
            ASN1ValueTooBigException = if encoded INTEGER is too large to decode.
            ASN1ValueInvalidException = if encoded ObjectDescriptor contains
                invalid characters.
            ASN1InvalidIndexException = if encoded value selects a choice for 
                identification or uses an unspecified index for an element in
                syntaxes or context-negotiation, or if an unspecified element
                of EMBEDDED PDV itself is referenced by an out-of-range 
                context-specific index. (See $(D_INLINECODE ASN1InvalidIndexException).)
    */
    override public @property @system
    EmbeddedPDV embeddedPresentationDataValue() const
    {
        DERElement[] dvs = this.sequence;
        if (dvs.length != 2)
            throw new ASN1ValueSizeException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EMBEDDED PDV that contained too many or too few elements. " ~
                "An EMBEDDED PDV should have exactly two elements: " ~
                "identification and data-value, in that order. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        if (dvs[0].type != 0x80u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because, you attempted to decode " ~
                "an EMBEDDED PDV whose elements were not exactly in the order " ~
                "they appear in the specification. Distinguished Encoding " ~
                "Rules (DER) specify that the encoded elements of any " ~
                "constructed type must appear in the order of their specification, " ~
                "which, in the case of EMBEDDED PDV, means that identification " ~
                "must appear first, then data-value. The problem in your case " ~
                "is that the first encoded element was not identification, as " ~
                "indicated by a context-specific type tag of 0x80." ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        if (dvs[1].type != 0x82u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because, you attempted to decode " ~
                "an EMBEDDED PDV whose elements were not exactly in the order " ~
                "they appear in the specification. Distinguished Encoding " ~
                "Rules (DER) specify that the encoded elements of any " ~
                "constructed type must appear in the order of their specification, " ~
                "which, in the case of EMBEDDED PDV, means that identification " ~
                "must appear first, then data-value. The problem in your case " ~
                "is that the second encoded element was not data-value, as " ~
                "indicated by a context-specific type tag of 0x82." ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        EmbeddedPDV pdv = EmbeddedPDV();
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();
        DERElement identificationElement = new DERElement(dvs[0].value);
        switch (identificationElement.type)
        {
            case (0xA0u): // syntaxes
            {
                ASN1ContextSwitchingTypeSyntaxes syntaxes = ASN1ContextSwitchingTypeSyntaxes();
                DERElement[] syns = identificationElement.sequence;
                if (syns.length != 2)
                    throw new ASN1ValueTooBigException
                    (
                        "This exception was thrown because you " ~
                        "attempted to decode an EMBEDDED PDV that had " ~
                        "too many elements within the syntaxes" ~
                        "element, which is supposed to " ~
                        "have only two elements. " ~ 
                        notWhatYouMeantText ~ forMoreInformationText ~ 
                        debugInformationText ~ reportBugsText
                    );
                syntaxes.abstractSyntax = syns[0].objectIdentifier;
                syntaxes.transferSyntax = syns[1].objectIdentifier;
                identification.syntaxes = syntaxes;
                break;
            }
            case (0x81u): // syntax
            {
                identification.syntax = identificationElement.objectIdentifier;
                break;
            }
            case (0x84u): // transfer-syntax
            {
                identification.transferSyntax = identificationElement.objectIdentifier;
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
                (
                    "This exception was thrown because you attempted " ~
                    "to decode an EMBEDDED PDV whose identification " ~
                    "CHOICE is not recognized by the specification. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );
            }
        }
        pdv.identification = identification;
        pdv.dataValue = dvs[1].octetString;
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

        In Distinguished Encoding Rules, the identification CHOICE cannot be
        presentation-context-id, nor context-negotiation. Also, the elements
        must appear in the exact order of the specification. With these 
        constraints in mind, the specification effectively becomes:

        $(I
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification [0] CHOICE {
                    syntaxes [0] SEQUENCE {
                        abstract [0] OBJECT IDENTIFIER,
                        transfer [1] OBJECT IDENTIFIER },
                    syntax [1] OBJECT IDENTIFIER,
                    transfer-syntax [4] OBJECT IDENTIFIER,
                    fixed [5] NULL },
                data-value [2] OCTET STRING }
        )

        If the supplied identification for the EmbeddedPDV is a 
        presentation-context-id or a context-negotiation, no exception will be
        thrown; the identification will be set to fixed silently.

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 5.

        Throws:
            ASN1ValueInvalidException = if encoded ObjectDescriptor contains
                invalid characters.
    */
    override public @property @system
    void embeddedPresentationDataValue(EmbeddedPDV value)
    {
        DERElement identification = new DERElement();
        identification.type = 0x80u; // CHOICE is EXPLICIT, even with automatic tagging.

        DERElement identificationValue = new DERElement();
        if (!(value.identification.syntaxes.isNull))
        {
            DERElement abstractSyntax = new DERElement();
            abstractSyntax.type = 0x80u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            DERElement transferSyntax = new DERElement();
            transferSyntax.type = 0x81u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationValue.type = 0xA0u;
            identificationValue.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationValue.type = 0x81u;
            identificationValue.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationValue.type = 0x84u;
            identificationValue.objectIdentifier = value.identification.transferSyntax;
        }
        else // Default to fixed
        {
            identificationValue.type = 0x85u;
            identificationValue.value = [];
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationValue;

        DERElement dataValue = new DERElement();
        dataValue.type = 0x82u;
        dataValue.octetString = value.dataValue;

        this.sequence = [ identification, dataValue ];
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because DER and CER
        do not support encoding of presentation-context-id in EMBEDDED PDV.

        This unit test ensures that, if you attempt to create an EMBEDDED PDV
        with presentation-context-id as the CHOICE of identification, the 
        encoded EMBEDDED PDV's identification defaults to fixed.
    */
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        EmbeddedPDV input = EmbeddedPDV();
        input.identification = id;
        input.dataValue = [ 0x01u, 0x02u, 0x03u, 0x04u ];

        DERElement el = new DERElement();
        el.type = 0x08u;
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.fixed == true);
        assert(output.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]);
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because DER and CER
        do not support encoding of context-negotiation in EMBEDDED PDV.

        This unit test ensures that, if you attempt to create an EMBEDDED PDV
        with context-negotiation as the CHOICE of identification, the 
        encoded EMBEDDED PDV's identification defaults to fixed.
    */
    @system
    unittest
    {
        ASN1ContextNegotiation cn = ASN1ContextNegotiation();
        cn.presentationContextID = 27L;
        cn.transferSyntax = new OID(1, 3, 6, 4, 1, 256, 39);

        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.contextNegotiation = cn;

        EmbeddedPDV input = EmbeddedPDV();
        input.identification = id;
        input.dataValue = [ 0x13u, 0x15u, 0x17u, 0x19u ];

        DERElement el = new DERElement();
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.fixed == true);
        assert(output.dataValue == [ 0x13u, 0x15u, 0x17u, 0x19u ]);
    }

    /**
        Decodes the value to UTF-8 characters.

        Throws:
            UTF8Exception if it does not decode correctly.
    */
    override public @property @system
    string unicodeTransformationFormat8String() const
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
    // REVIEW: This could probably be a lot faster if you combine all three loops.
    override public @property @system
    OIDNode[] relativeObjectIdentifier() const
    {
        ubyte[][] components;
        size_t[] numbers = [];
        Appender!(OIDNode[]) nodes = appender!(OIDNode[])();
        
        // Breaks bytes into groups, where each group encodes one OID number.
        ptrdiff_t lastTerminator = 0;
        for (int i = 0; i < this.length; i++)
        {
            if (!(this.value[i] & 0x80u))
            {
                components ~= cast(ubyte[]) this.value[lastTerminator .. i+1];
                lastTerminator = i+1;
            }
        }

        // Converts each group of bytes to a number.
        foreach (component; components)
        {
            if (component.length > (size_t.sizeof * 2u))
                throw new ASN1ValueTooBigException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a RELATIVE OID that encoded a number on more than " ~
                    "size_t*2 bytes (16 on 64-bit, 8 on 32-bit). " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            numbers ~= 0u;
            for (ptrdiff_t i = 0; i < component.length; i++)
            {
                numbers[$-1] <<= 7;
                numbers[$-1] |= cast(size_t) (component[i] & 0x7Fu);
            }
        }
        
        // Constructs the array of OIDNodes from the array of numbers.
        foreach (number; numbers)
        {
            nodes.put(OIDNode(number));
        }

        return nodes.data;
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
    override public @property @system nothrow
    void relativeObjectIdentifier(OIDNode[] value)
    {
        foreach (node; value)
        {
            size_t number = node.number;
            ubyte[] encodedOIDComponent;
            if (number < 128u)
            {
                this.value ~= cast(ubyte) number;
                continue;
            }
            while (number != 0u)
            {
                ubyte[] compbytes;
                compbytes.length = size_t.sizeof;
                *cast(size_t *) compbytes.ptr = number;
                if ((compbytes[0] & 0x80u) == 0) compbytes[0] |= 0x80u;
                encodedOIDComponent = compbytes[0] ~ encodedOIDComponent;
                number >>= 7;
            }
            encodedOIDComponent[$-1] &= 0x7Fu;
            this.value ~= encodedOIDComponent;
        }
    }

    /**
        Decodes a sequence of DERElements.

        Returns: an array of DERElements.
        Throws:
            ASN1ValueSizeException = if long definite-length is too big to be
                decoded to an unsigned integral type.
            ASN1ValueTooSmallException = if there are fewer value bytes than
                indicated by the length tag.
    */
    override public @property @system
    DERElement[] sequence() const
    {
        ubyte[] data = this.value.dup;
        DERElement[] result;
        while (data.length > 0u)
            result ~= new DERElement(data);
        return result;
    }

    /**
        Encodes a sequence of DERElements.
    */
    override public @property @system
    void sequence(DERElement[] value)
    {
        ubyte[] result;
        foreach (dv; value)
        {
            result ~= cast(ubyte[]) dv;
        }
        this.value = result;
    }

    /**
        Decodes a set of DERElements.

        Returns: an array of DERElements.
        Throws:
            ASN1ValueSizeException = if long definite-length is too big to be
                decoded to an unsigned integral type.
            ASN1ValueTooSmallException = if there are fewer value bytes than
                indicated by the length tag.
    */
    override public @property @system
    DERElement[] set() const
    {
        ubyte[] data = this.value.dup;
        DERElement[] result;
        while (data.length > 0u)
            result ~= new DERElement(data);
        return result;
    }

    /**
        Encodes a set of DERElements.
    */
    override public @property @system
    void set(DERElement[] value)
    {
        ubyte[] result;
        foreach (dv; value)
        {
            result ~= cast(ubyte[]) dv;
        }
        this.value = result;
    }

    /**
        Decodes a string, where the characters of the string are limited to
        0 - 9 and space.

        Returns: a string.
        Throws:
            ASN1ValueInvalidException = if any character other than 0-9 or
                space is encoded.
    */
    override public @property @system
    string numericString() const
    {
        foreach (character; this.value)
        {
            if (!canFind(numericStringCharacters, character))
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a NumericString that contained a character that " ~
                    "is not numeric or space. The encoding of the offending character is '" ~
                    character ~ "'. " ~ notWhatYouMeantText ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        return cast(string) this.value;
    }

    /**
        Encodes a string, where the characters of the string are limited to
        0 - 9 and space.

        Throws:
            ASN1ValueInvalidException = if any character other than 0-9 or
                space is supplied.
    */
    override public @property @system
    void numericString(string value)
    {
        foreach (character; value)
        {
            if (!canFind(numericStringCharacters, character))
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a NumericString that contained a character that " ~
                    "is not numeric or space. The encoding of the offending character is '" ~
                    character ~ "'. " ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );
        }
        this.value = cast(ubyte[]) value;
    }

    /**
        Decodes a string that will only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period, 
        forward slash, colon, equals, and question mark.

        Returns: a string.
        Throws:
            ASN1ValueInvalidException = if any character other than a-z, A-Z, 
                0-9, space, apostrophe, parentheses, comma, minus, plus,
                period, forward slash, colon, equals, or question mark are
                encoded.
    */
    override public @property @system
    string printableString() const
    {
        foreach (character; this.value)
        {
            if (!canFind(printableStringCharacters, character))
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a PrintableString that contained a character that " ~
                    "is not considered 'printable' by the specification. " ~
                    "The encoding of the offending character is '" ~ text(cast(uint) character) ~ "'. " ~
                    "The allowed characters are: " ~ printableStringCharacters ~ " " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );
        }
        return cast(string) this.value;
    }

    /**
        Encodes a string that may only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period, 
        forward slash, colon, equals, and question mark.

        Throws:
            ASN1ValueInvalidException = if any character other than a-z, A-Z, 
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
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to encode " ~
                    "a PrintableString that contained a character that " ~
                    "is not considered 'printable' by the specification. " ~
                    "The encoding of the offending character is '" ~ text(cast(uint) character) ~ "'. " ~
                    "The allowed characters are: " ~ printableStringCharacters ~ " " ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        this.value = cast(ubyte[]) value;
    }
   
    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array, where each byte is a T.61 character.
    */
    override public @property @safe nothrow
    ubyte[] teletexString() const
    {
        // TODO: Validation.
        return this.value.dup;
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

    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array.
    */
    override public @property @safe nothrow
    ubyte[] videotexString() const
    {
        // TODO: Validation.
        return this.value.dup;
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
            ASN1ValueInvalidException = if any enecoded character is not ASCII.
    */
    override public @property @system
    string internationalAlphabetNumber5String() const
    {
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isASCII)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "an IA5String that contained a character that " ~
                    "is not ASCII. The encoding of the offending character is '" ~ text(cast(uint) character) ~ "'. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );
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
            ASN1ValueInvalidException = if any enecoded character is not ASCII.
    */
    override public @property @system
    void internationalAlphabetNumber5String(string value)
    {
        foreach (character; value)
        {
            if (!character.isASCII)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "an IA5String that contained a character that " ~
                    "is not ASCII. The encoding of the offending character is '" ~ text(cast(uint) character) ~ "'. " ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        this.value = cast(ubyte[]) value;
    } 

    /**
        Decodes a DateTime.
        
        The DER-encoded value is just the ASCII character representation of
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
        
        Throws:
            DateTimeException = if string cannot be decoded to a DateTime
    */
    override public @property @system
    DateTime coordinatedUniversalTime() const
    {
        /** NOTE:
            .fromISOString() MUST be called from SysTime, not DateTime. There 
            is a subtle difference in how .fromISOString() works in both SysTime
            and DateTime: SysTime's accepts the "Z" at the end (indicating that
            the time is in GMT).

            If you use DateTime.fromISOString, you will get a DateTimeException
            whose cryptic message reads "Invalid ISO String: " followed,
            strangely, by only the last six characters of the string.
        */
        string dt = (((this.value[0] <= '7') ? "20" : "19") ~ cast(string) this.value);
        return cast(DateTime) SysTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    /**
        Encodes a DateTime.
        
        The DER-encoded value is just the ASCII character representation of
        the UTC-formatted timestamp.

        An UTC Timestamp looks like: 
        $(UL
            $(LI 9912312359Z)
            $(LI 991231235959+0200)
        )

        See_Also:
            $(LINK2 https://www.obj-sys.com/asn1tutorial/node15.html, UTCTime)
    */
    override public @property @system
    void coordinatedUniversalTime(DateTime value)
    {
        import std.string : replace;
        SysTime st = SysTime(value, UTC());
        this.value = cast(ubyte[]) ((st.toUTC()).toISOString()[2 .. $].replace("T", ""));
    }

    /**
        Decodes a DateTime.

        The DER-encoded value is just the ASCII character representation of
        the $(LINK2 https://www.iso.org/iso-8601-date-and-time-format.html, 
        ISO 8601)-formatted timestamp.

        An ISO-8601 Timestamp looks like: 
        $(UL
            $(LI 19851106210627.3)
            $(LI 19851106210627.3Z)
            $(LI 19851106210627.3-0500)
        )

        Throws:
            DateTimeException = if string cannot be decoded to a DateTime
    */
    override public @property @system
    DateTime generalizedTime() const
    {
        /** NOTE:
            .fromISOString() MUST be called from SysTime, not DateTime. There 
            is a subtle difference in how .fromISOString() works in both SysTime
            and DateTime: SysTime's accepts the "Z" at the end (indicating that
            the time is in GMT).

            If you use DateTime.fromISOString, you will get a DateTimeException
            whose cryptic message reads "Invalid ISO String: " followed,
            strangely, by only the last six characters of the string.
        */
        string dt = cast(string) this.value;
        return cast(DateTime) SysTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    /**
        Encodes a DateTime.

        The DER-encoded value is just the ASCII character representation of
        the $(LINK2 https://www.iso.org/iso-8601-date-and-time-format.html, 
        ISO 8601)-formatted timestamp.

        An ISO-8601 Timestamp looks like: 
        $(UL
            $(LI 19851106210627.3)
            $(LI 19851106210627.3Z)
            $(LI 19851106210627.3-0500)
        )
    */
    override public @property @system
    void generalizedTime(DateTime value)
    {
        import std.string : replace;
        SysTime st = SysTime(value, UTC());
        this.value = cast(ubyte[]) ((st.toUTC()).toISOString().replace("T", ""));
    }

    /**
        Decodes an ASCII string that contains only characters between and 
        including 0x20 and 0x75.

        Deprecated, according to page 182 of the Dubuisson book.

        Citations:
            Dubuisson, Olivier. “Character String Types.” ASN.1: 
                Communication between Heterogeneous Systems, Morgan 
                Kaufmann, 2001, pp. 175-178.
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

        Returns: a string.
        Throws:
            ASN1ValueInvalidException = if any non-graphical character 
                (including space) is encoded.
    */
    override public @property @system
    string graphicString() const
    {
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a GraphicString that contained a character that " ~
                    "is not graphical (a character whose ASCII encoding " ~
                    "is outside of the range 0x20 to 0x7E). The encoding of the offending " ~
                    "character is '" ~ text(cast(uint) character) ~ "'. " ~ notWhatYouMeantText ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        return ret;
    }

    /**
        Encodes an ASCII string that may contain only characters between and 
        including 0x20 and 0x75.

        Deprecated, according to page 182 of the Dubuisson book.

        Citations:
            Dubuisson, Olivier. “Character String Types.” ASN.1: 
                Communication between Heterogeneous Systems, Morgan 
                Kaufmann, 2001, pp. 175-178.
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

        Throws:
            ASN1ValueInvalidException = if any non-graphical character 
                (including space) is supplied.
    */
    override public @property @system
    void graphicString(string value)
    {
        foreach (character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to encode " ~
                    "a GraphicString that contained a character that " ~
                    "is not graphical (a character whose ASCII encoding " ~
                    "is outside of the range 0x20 to 0x7E). The encoding of the offending " ~
                    "character is '" ~ text(cast(uint) character) ~ "'. " ~ 
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        this.value = cast(ubyte[]) value;
    }

    /**
        Decodes a string that only contains characters between and including
        0x20 and 0x7E. (Honestly, I don't know how this differs from
        GraphicalString.)

        Returns: a string.
        Throws:
            ASN1ValueInvalidException = if any non-graphical character 
                (including space) is encoded.
    */
    override public @property @system
    string visibleString() const
    {
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a VisibleString that contained a character that " ~
                    "is not graphical (a character whose ASCII encoding " ~
                    "is outside of the range 0x20 to 0x7E) or space. The encoding of the offending " ~
                    "character is '" ~ text(cast(uint) character) ~ "'. " ~ notWhatYouMeantText ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        return ret;
    }

    /**
        Encodes a string that only contains characters between and including
        0x20 and 0x7E. (Honestly, I don't know how this differs from
        GraphicalString.)

        Throws:
            ASN1ValueInvalidException = if any non-graphical character 
                (including space) is supplied.
    */
    override public @property @system
    void visibleString(string value)
    {
        foreach (character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a VisibleString that contained a character that " ~
                    "is not graphical (a character whose ASCII encoding " ~
                    "is outside of the range 0x20 to 0x7E) or space. The encoding of the offending " ~
                    "character is '" ~ text(cast(uint) character) ~ "'. " ~ 
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        this.value = cast(ubyte[]) value;
    }

    /**
        Decodes a string containing only ASCII characters.

        Deprecated, according to page 182 of the Dubuisson book.

        Returns: a string.
        Throws:
            ASN1ValueInvalidException = if any enecoded character is not ASCII.

        Citations:
            Dubuisson, Olivier. “Distinguished Encoding Rules (DER).” ASN.1: 
            Communication between Heterogeneous Systems, Morgan Kaufmann, 
            2001, p. 182.
    */
    override public @property @system
    string generalString() const
    {
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isASCII)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "an GeneralString that contained a character that " ~
                    "is not ASCII. The encoding of the offending character is '" ~ text(cast(uint) character) ~ "'. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );
        }
        return ret;
    }

    /**
        Encodes a string containing only ASCII characters.

        Deprecated, according to page 182 of the Dubuisson book.

        Throws:
            ASN1ValueInvalidException = if any enecoded character is not ASCII.

        Citations:
            Dubuisson, Olivier. “Distinguished Encoding Rules (DER).” ASN.1: 
            Communication between Heterogeneous Systems, Morgan Kaufmann, 
            2001, p. 182.
    */
    override public @property @system
    void generalString(string value)
    {
        foreach (character; value)
        {
            if (!character.isASCII)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "an GeneralString that contained a character that " ~
                    "is not ASCII. The encoding of the offending character is '" ~ text(cast(uint) character) ~ "'. " ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        this.value = cast(ubyte[]) value;
    }

    /**
        Decodes a dstring of UTF-32 characters.

        Returns: a string of UTF-32 characters.
        Throws:
            ASN1ValueInvalidException = if the encoded bytes is not evenly
                divisible by four.
    */
    override public @property @system
    dstring universalString() const
    {
        if (this.value.length == 0u) return ""d;
        if (this.value.length % 4u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you tried to decode " ~
                "a UniversalString that contained a number of bytes that " ~
                "is not divisible by four. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        version (BigEndian)
        {
            return cast(dstring) this.value;
        }
        else version (LittleEndian)
        {
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
    override public @property @system
    CharacterString characterString() const
    {
        DERElement[] dvs = this.sequence;
        if (dvs.length != 2)
            throw new ASN1ValueSizeException
            (
                "This exception was thrown because you attempted to decode " ~
                "an CharacterString that contained too many or too few elements. " ~
                "An CharacterString should have exactly two elements: " ~
                "identification and string-value, in that order. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        if (dvs[0].type != 0x80u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because, you attempted to decode " ~
                "an CharacterString whose elements were not exactly in the order " ~
                "they appear in the specification. Distinguished Encoding " ~
                "Rules (DER) specify that the encoded elements of any " ~
                "constructed type must appear in the order of their specification, " ~
                "which, in the case of CharacterString, means that identification " ~
                "must appear first, then string-value. The problem in your case " ~
                "is that the first encoded element was not identification, as " ~
                "indicated by a context-specific type tag of 0x80." ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        if (dvs[1].type != 0x81u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because, you attempted to decode " ~
                "an CharacterString whose elements were not exactly in the order " ~
                "they appear in the specification. Distinguished Encoding " ~
                "Rules (DER) specify that the encoded elements of any " ~
                "constructed type must appear in the order of their specification, " ~
                "which, in the case of CharacterString, means that identification " ~
                "must appear first, then string-value. The problem in your case " ~
                "is that the second encoded element was not string-value, as " ~
                "indicated by a context-specific type tag of 0x81." ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        CharacterString cs = CharacterString();
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();
        DERElement identificationElement = new DERElement(dvs[0].value);
        switch (identificationElement.type)
        {
            case (0x80u): // syntaxes
            {
                ASN1ContextSwitchingTypeSyntaxes syntaxes = ASN1ContextSwitchingTypeSyntaxes();
                DERElement[] syns = identificationElement.sequence;
                if (syns.length != 2)
                    throw new ASN1ValueTooBigException
                    (
                        "This exception was thrown because you " ~
                        "attempted to decode an EMBEDDED PDV that had " ~
                        "too many elements within the syntaxes" ~
                        "element, which is supposed to " ~
                        "have only two elements. " ~ 
                        notWhatYouMeantText ~ forMoreInformationText ~ 
                        debugInformationText ~ reportBugsText
                    );
                syntaxes.abstractSyntax = syns[0].objectIdentifier;
                syntaxes.transferSyntax = syns[1].objectIdentifier;
                identification.syntaxes = syntaxes;
                break;
            }
            case (0x81u): // syntax
            {
                identification.syntax = identificationElement.objectIdentifier;
                break;
            }
            case (0x84u): // transfer-syntax
            {
                identification.transferSyntax = identificationElement.objectIdentifier;
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
                (
                    "This exception was thrown because you attempted " ~
                    "to decode an CharacterString whose identification " ~
                    "CHOICE is not recognized by the specification. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );
            }
        }
        cs.identification = identification;
        cs.stringValue = dvs[1].octetString;
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
    override public @property @system
    void characterString(CharacterString value)
    {
        DERElement identification = new DERElement();
        identification.type = 0x80u; // CHOICE is EXPLICIT, even with automatic tagging.

        DERElement identificationValue = new DERElement();
        if (!(value.identification.syntaxes.isNull))
        {
            DERElement abstractSyntax = new DERElement();
            abstractSyntax.type = 0x80u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            DERElement transferSyntax = new DERElement();
            transferSyntax.type = 0x81u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationValue.type = 0x80u;
            identificationValue.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationValue.type = 0x81u;
            identificationValue.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationValue.type = 0x84u;
            identificationValue.objectIdentifier = value.identification.transferSyntax;
        }
        else // Default to fixed
        {
            identificationValue.type = 0x85u;
            identificationValue.value = [];
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationValue;

        DERElement stringValue = new DERElement();
        stringValue.type = 0x81u;
        stringValue.octetString = value.stringValue;

        this.sequence = [ identification, stringValue ];
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because DER and CER
        do not support encoding of context-negotiation in CharacterString.

        This unit test ensures that, if you attempt to create a CharacterString
        with context-negotiation as the CHOICE of identification, the 
        encoded CharacterString's identification defaults to fixed.
    */
    @system
    unittest
    {
        ASN1ContextNegotiation cn = ASN1ContextNegotiation();
        cn.presentationContextID = 27L;
        cn.transferSyntax = new OID(1, 3, 6, 4, 1, 256, 39);

        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.contextNegotiation = cn;

        CharacterString input = CharacterString();
        input.identification = id;
        input.stringValue = [ 'H', 'E', 'N', 'L', 'O' ];

        DERElement el = new DERElement();
        el.characterString = input;
        CharacterString output = el.characterString;
        assert(output.identification.fixed == true);
        assert(output.stringValue == [ 'H', 'E', 'N', 'L', 'O' ]);
    }

    /**
        Decodes a wstring of UTF-16 characters.

        Returns: an immutable array of UTF-16 characters.
        Throws:
            ASN1ValueInvalidException = if the encoded bytes is not evenly
                divisible by two.
    */
    override public @property @system
    wstring basicMultilingualPlaneString() const
    {
        if (this.value.length == 0u) return ""w;
        if (this.value.length % 2u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you tried to decode " ~
                "a BMPString that contained a number of bytes that " ~
                "is not divisible by two. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        version (BigEndian)
        {
            return cast(wstring) this.value;
        }
        else version (LittleEndian)
        {
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

    /**
        Creates an EndOfContent DER Value.
    */
    public @safe @nogc nothrow
    this()
    {
        this.type = 0x00;
        this.value = [];
    }

    /**
        Creates a DERElement from the supplied bytes, inferring that the first
        byte is the type tag. The supplied ubyte[] array is "chomped" by
        reference, so the original array will grow shorter as DERElements are
        generated. 

        Throws:
            ASN1ValueTooSmallException = if the bytes supplied are fewer than
                two (one or zero, in other words), such that no valid DERElement
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
        DERElement[] result;
        while (bytes.length > 0)
            result ~= new DERElement(bytes);

        // Encoding looks like:
        ubyte[] result;
        foreach (dv; bervalues)
        {
            result ~= cast(ubyte[]) dv;
        }
        ---
    */
    public @system
    this(ref ubyte[] bytes)
    {
        if (bytes.length < 2u)
            throw new ASN1ValueTooSmallException
            ("DER-encoded value terminated prematurely.");
        
        this.type = bytes[0];
        
        // Length
        if (bytes[1] & 0x80u)
        {
            immutable ubyte numberOfLengthOctets = (bytes[1] & 0x7Fu);
            if (numberOfLengthOctets) // Definite Long or Reserved
            {
                if (numberOfLengthOctets == 0x7Fu) // Reserved
                    throw new ASN1InvalidLengthException
                    ("A DER-encoded length byte of 0xFF is reserved.");

                // Definite Long, if it has made it this far

                if (numberOfLengthOctets > size_t.sizeof)
                    throw new ASN1ValueTooBigException
                    ("DER-encoded value is too big to decode.");

                ubyte[] lengthBytes;
                lengthBytes.length = size_t.sizeof;
                
                // REVIEW: I sense that there is a simpler loop that would work.
                for (ubyte i = numberOfLengthOctets; i > 0u; i--)
                {
                    lengthBytes[size_t.sizeof-i] = bytes[2+numberOfLengthOctets-i];
                }
                version (LittleEndian) reverse(lengthBytes);

                size_t startOfValue = (2u + numberOfLengthOctets);
                size_t length = *cast(size_t *) lengthBytes.ptr;
                this.value = bytes[startOfValue .. startOfValue+length];
                bytes = bytes[startOfValue+length .. $];
            }
            else // Indefinite
            {   
                throw new ASN1InvalidLengthException
                (
                    "This exception was thrown because an invalid length tag " ~
                    "was encountered. Distinguished Encoding Rules (DER) do not " ~
                    "permit indefinite-length encoded data. Are you sure you are " ~
                    "using the correct codec?"
                );
            }
        }
        else // Definite Short
        {
            ubyte length = (bytes[1] & 0x7Fu);

            if (length > (bytes.length-2))
                throw new ASN1ValueTooSmallException
                ("DER-encoded value terminated prematurely.");

            this.value = bytes[2 .. 2+length].dup;
            bytes = bytes[2+length .. $];
        }
    }

    /**
        Creates a DERElement from the supplied bytes, inferring that the first
        byte is the type tag. The supplied ubyte[] array is read, starting
        from the index specified by $(D bytesRead), and increments 
        $(D bytesRead) by the number of bytes read.

        Throws:
            ASN1ValueTooSmallException = if the bytes supplied are fewer than
                two (one or zero, in other words), such that no valid DERElement
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
        DERElement[] result;
        size_t i = 0u;
        while (i < bytes.length)
            result ~= new DERElement(i, bytes);

        // Encoding looks like:
        ubyte[] result;
        foreach (dv; bervalues)
        {
            result ~= cast(ubyte[]) dv;
        }
        ---
    */
    public @system
    this(ref size_t bytesRead, ref ubyte[] bytes)
    {
        if (bytes.length < (bytesRead + 2u))
            throw new ASN1ValueTooSmallException
            ("DER-encoded value terminated prematurely.");
        
        this.type = bytes[bytesRead];

        // Length
        if (bytes[bytesRead+1] & 0x80u)
        {
            immutable ubyte numberOfLengthOctets = (bytes[bytesRead+1] & 0x7Fu);            
            if (numberOfLengthOctets) // Definite Long or Reserved
            {
                if (numberOfLengthOctets == 0x7Fu) // Reserved
                    throw new ASN1InvalidLengthException
                    ("A DER-encoded length byte of 0xFF is reserved.");

                // Definite Long, if it has made it this far

                if (numberOfLengthOctets > size_t.sizeof)
                    throw new ASN1ValueTooBigException
                    ("DER-encoded value is too big to decode.");

                ubyte[] lengthBytes;
                lengthBytes.length = size_t.sizeof;
                
                // REVIEW: I sense that there is a simpler loop that would work.
                for (ubyte i = numberOfLengthOctets; i > 0u; i--)
                {
                    lengthBytes[size_t.sizeof-i] = bytes[bytesRead+2+numberOfLengthOctets-i];
                }
                version (LittleEndian) reverse(lengthBytes);

                size_t startOfValue = (bytesRead + 2 + numberOfLengthOctets);
                size_t length = *cast(size_t *) lengthBytes.ptr;
                this.value = bytes[startOfValue .. startOfValue+length];
                bytesRead += (2 + numberOfLengthOctets + length);
            }
            else // Indefinite
            {   
                throw new ASN1InvalidLengthException
                (
                    "This exception was thrown because an invalid length tag " ~
                    "was encountered. Distinguished Encoding Rules (DER) do not " ~
                    "permit indefinite-length encoded data. Are you sure you are " ~
                    "using the correct codec?"
                );
            }
        }
        else // Definite Short
        {
            ubyte length = (bytes[bytesRead+1] & 0x7Fu);

            if ((length+bytesRead) > (bytes.length-2u))
                throw new ASN1ValueTooSmallException
                ("DER-encoded value terminated prematurely.");

            this.value = bytes[bytesRead+2u .. bytesRead+length+2u].dup;
            bytesRead += (2u + length);
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
    public @property @system nothrow
    ubyte[] toBytes() const
    {
        ubyte[] lengthOctets = [ 0x00u ];
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

        return ([ this.type ] ~ lengthOctets ~ this.value);
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
        return this.toBytes();
    }

}

// Tests of all types using definite-short encoding.
@system
unittest
{
    // Test data
    ubyte[] dataEndOfContent = [ 0x00u, 0x00u ];
    ubyte[] dataBoolean = [ 0x01u, 0x01u, 0xFFu ];
    ubyte[] dataInteger = [ 0x02u, 0x08u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0xFFu ];
    ubyte[] dataBitString = [ 0x03u, 0x03u, 0x07u, 0xF0u, 0xF0u ];
    ubyte[] dataOctetString = [ 0x04u, 0x04u, 0xFF, 0x00u, 0x88u, 0x14u ];
    ubyte[] dataNull = [ 0x05u, 0x00u ];
    ubyte[] dataOID = [ 0x06u, 0x04u, 0x2Bu, 0x06u, 0x04u, 0x01u ];
    ubyte[] dataOD = [ 0x07u, 0x05u, 'H', 'N', 'E', 'L', 'O' ];
    ubyte[] dataExternal = [ 
        0x08u, 0x18u, 0x80u, 0x06u, 0x80u, 0x04u, 0x29u, 0x06u, 
        0x04u, 0x01u, 0x81u, 0x08u, 0x65u, 0x78u, 0x74u, 0x65u, 
        0x72u, 0x6Eu, 0x61u, 0x6Cu, 0x82u, 0x04u, 0x01u, 0x02u, 
        0x03u, 0x04u ];
    ubyte[] dataReal = [ 0x09u, 0x03u, 0x80u, 0xFBu, 0x05u ]; // 0.15625 (From StackOverflow question)
    ubyte[] dataEnum = [ 0x0Au, 0x08u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0xFFu ];
    ubyte[] dataEmbeddedPDV = [ 
        0x0Bu, 0x0Au, 0x80u, 0x02u, 0x85u, 0x00u, 0x82u, 0x04u, 
        0x01u, 0x02u, 0x03u, 0x04u ];
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
        0x1Du, 0x0Fu, 0x80u, 0x06u, 0x81u, 0x04u, 0x29u, 0x06u, 
        0x04u, 0x01u, 0x81u, 0x05u, 0x48u, 0x45u, 0x4Eu, 0x4Cu, 
        0x4Fu ];
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

    DERElement[] result;

    size_t i = 0u;
    while (i < data.length)
        result ~= new DERElement(i, data);

    // Pre-processing
    External x = result[8].external;
    EmbeddedPDV m = result[11].embeddedPresentationDataValue;
    CharacterString c = result[25].characterString;

    // Ensure accessors decode the data correctly.
    assert(result[1].boolean == true);
    assert(result[2].integer!long == 255L);
    assert(result[3].bitString == [ true, true, true, true, false, false, false, false, true ]);
    assert(result[4].octetString == [ 0xFFu, 0x00u, 0x88u, 0x14u ]);
    assert(result[6].objectIdentifier == new OID(OIDNode(0x01u), OIDNode(0x03u), OIDNode(0x06u), OIDNode(0x04u), OIDNode(0x01u)));
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert((x.identification.syntax == new OID(1u, 1u, 6u, 4u, 1u)) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[9].realType!float == 0.15625);
    assert(result[9].realType!double == 0.15625);
    assert(result[10].enumerated!long == 255L);
    assert((m.identification.fixed == true) && (m.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[12].utf8String == "HENLO");
    assert(result[13].relativeObjectIdentifier == [ OIDNode(6), OIDNode(4), OIDNode(1) ]);
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
    assert((c.identification.syntax == new OID(1u, 1u, 6u, 4u, 1u)) && (c.stringValue == "HENLO"w));

    result = [];
    while (data.length > 0)
        result ~= new DERElement(data);

    // Pre-processing
    x = result[8].external;
    m = result[11].embeddedPresentationDataValue;
    c = result[25].characterString;

    // Ensure accessors decode the data correctly.
    assert(result[1].boolean == true);
    assert(result[2].integer!long == 255L);
    assert(result[3].bitString == [ true, true, true, true, false, false, false, false, true ]);
    assert(result[4].octetString == [ 0xFFu, 0x00u, 0x88u, 0x14u ]);
    assert(result[6].objectIdentifier == new OID(OIDNode(0x01u), OIDNode(0x03u), OIDNode(0x06u), OIDNode(0x04u), OIDNode(0x01u)));
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert((x.identification.syntax == new OID(1u, 1u, 6u, 4u, 1u)) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[9].realType!float == 0.15625);
    assert(result[9].realType!double == 0.15625);
    assert(result[10].enumerated!long == 255L);
    assert((m.identification.fixed == true) && (m.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[12].utf8String == "HENLO");
    assert(result[13].relativeObjectIdentifier == [ OIDNode(6), OIDNode(4), OIDNode(1) ]);
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
    assert((c.identification.syntax == new OID(1u, 1u, 6u, 4u, 1u)) && (c.stringValue == "HENLO"w));
}

// Test of definite-long encoding
@system
unittest
{
    ubyte[] data = [ // 192 characters of boomer-posting
        0x0Cu, 0x81u, 0xC0, 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n'  
    ];

    data = (data ~ data ~ data); // Triple the data, to catch any bugs that arise with subsequent values.

    DERElement[] result;
    size_t i = 0u;
    while (i < data.length)
        result ~= new DERElement(i, data);
        
    assert(result.length == 3);
    assert(result[0].utf8String[0 .. 5] == "AMREN");
    assert(result[1].utf8String[6 .. 14] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');

    result = [];
    while (data.length > 0)
        result ~= new DERElement(data);
        
    assert(result.length == 3);
    assert(result[0].utf8String[0 .. 5] == "AMREN");
    assert(result[1].utf8String[6 .. 14] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');
}

// Test that indefinite-length encoding throws an exception.
@system
unittest
{
    ubyte[] data = [ // 192 characters of boomer-posting
        0x0Cu, 0x80u, 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n', 
        'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x00u, 0x00u
    ];

    data = (data ~ data ~ data); // Triple the data, to catch any bugs that arise with subsequent values.
    
    size_t i = 0u;
    assertThrown!ASN1InvalidLengthException(new DERElement(i, data));
    assertThrown!ASN1InvalidLengthException(new DERElement(data));
}

/*
    Test of OCTET STRING encoding on 500 bytes (+4 for type and length tags)

    The number 500 was specifically selected for this test because CER
    uses 1000 as the threshold after which OCTET STRING must be represented
    as a constructed sequence of definite-length-encoded OCTET STRINGS, 
    followed by an EOC element, but 500 is also big enough to require
    the length to be encoded on two octets in definite-long form.
*/
@system
unittest
{
    ubyte[] test;
    test.length = 504u;
    test[0] = cast(ubyte) ASN1UniversalType.octetString;
    test[1] = 0b1000_0010u; // Length is encoded on next two octets
    test[2] = 0x01u; // Most significant byte of length
    test[3] = 0xF4u; // Least significant byte of length
    test[4] = 0x0Au; // First byte of the encoded value
    test[5 .. $-1] = 0x0Bu;
    test[$-1] = 0x0Cu;

    DERElement el;
    assertNotThrown!Exception(el = new DERElement(test));
    ubyte[] output = el.octetString;
    assert(output.length == 500u);
    assert(output[0] == 0x0Au);
    assert(output[1] == 0x0Bu);
    assert(output[$-2] == 0x0Bu);
    assert(output[$-1] == 0x0Cu);
}

// Assert all single-byte encodings do not decode successfully.
@system
unittest
{
    for (ubyte i = 0x00u; i < ubyte.max; i++)
    {
        ubyte[] data = [i];
        assertThrown!Exception(new DERElement(data));
    }

    size_t index;
    for (ubyte i = 0x00u; i < ubyte.max; i++)
    {
        ubyte[] data = [i];
        assertThrown!Exception(new DERElement(index, data));
    }
}