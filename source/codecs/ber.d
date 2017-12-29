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
    License: $(LINK2 https://mit-license.org/, MIT License)
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
public import interfaces : Byteable;
public import types.identification;

///
public alias berOID = basicEncodingRulesObjectIdentifier;
///
public alias berObjectID = basicEncodingRulesObjectIdentifier;
///
public alias berObjectIdentifier = basicEncodingRulesObjectIdentifier;
/**
    The object identifier assigned to the Basic Encoding Rules (BER), per the
    $(LINK2 http://www.itu.int/en/pages/default.aspx,
        International Telecommunications Union)'s,
    $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

    $(I {joint-iso-itu-t asn1 (1) basic-encoding (1)} )
*/
public immutable OID basicEncodingRulesObjectIdentifier = cast(immutable(OID)) new OID(2, 1, 1);

///
public alias BERElement = BasicEncodingRulesElement;
/**
    The unit of encoding and decoding for Basic Encoding Rules (BER).

    There are three parts to an element encoded according to the Basic
    Encoding Rules (BER):

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
    BERElement bv = new BERElement();
    bv.tagNumber = 0x02u; // "2" means this is an INTEGER
    bv.integer = 1433; // Now the data is encoded.
    transmit(cast(ubyte[]) bv); // transmit() is a made-up function.
    ---

    And this is what decoding looks like:

    ---
    ubyte[] data = receive(); // receive() is a made-up function.
    BERElement bv2 = new BERElement(data);

    long x;
    if (bv.tagNumber == 0x02u) // it is an INTEGER
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
class BasicEncodingRulesElement : ASN1Element!BERElement, Byteable
{
    @system
    unittest
    {
        writeln("Running unit tests for codec: " ~ typeof(this).stringof);
    }

    /**
        Unlike most other settings, this is non-static, because wanting to
        encode with indefinite length is probably going to be somewhat rare,
        and it is also less safe, because the value octets have to be inspected
        for double octets before encoding! (If they are not, the receiver will
        interpret those inner null octets as the terminator for the indefinite
        length value, and the rest will be truncated.)
    */
    public LengthEncodingPreference lengthEncodingPreference =
        LengthEncodingPreference.definite;

    /// The base of encoded REALs. May be 2, 8, 10, or 16.
    static public ASN1RealEncodingBase realEncodingBase = ASN1RealEncodingBase.base2;

    /// The number of recursions used for parsing constructed elements.
    static protected size_t nestingRecursionCount = 0u;

    /// The limit of recursions permitted for parsing constructed elements.
    static immutable size_t nestingRecursionLimit = 5u;

    public ASN1TagClass tagClass;
    public ASN1Construction construction;
    public size_t tagNumber;

    /// The length of the value in octets
    public @property @safe nothrow
    size_t length() const
    {
        return this.value.length;
    }

    /*
        I have been on the fence about this for a while now: I don't want
        developers directly setting the bytes of the value. I know that making
        value a public member means that some idiot somewhere is going to
        bypass all of the methods I made and just directly set values himself,
        resulting in some catastrophic bug in a major library or program
        somewhere.

        But on the other hand, if I make value a private member, and readable
        only via property, then the same idiot that would have directly set
        value could just directly set the value using the octetString method.

        So either way, I can't stop anybody from doing something dumb with this
        code. As Ron White says: you can't fix stupid. So value is going to be
        a public member. But don't touch it.
    */
    public ubyte[] value;

    /**
        Decodes a boolean.

        Any non-zero value will be interpreted as TRUE. Only zero will be
        interpreted as FALSE.

        Returns: a boolean
        Throws:
            ASN1ValueSizeException = if the encoded value is anything other
                than exactly 1 byte in size.
    */
    override public @property @safe
    bool boolean() const
    {
        if (this.value.length != 1u)
            throw new ASN1ValueSizeException
            (
                "In Basic Encoding Rules, a BOOLEAN must be encoded on exactly " ~
                "one byte (in addition to the type and length bytes, of " ~
                "course). This exception was thrown because you attempted to " ~
                "decode a BOOLEAN from an element that had either zero or more " ~
                "than one bytes as the encoded value. " ~ notWhatYouMeantText ~
                forMoreInformationText ~ debugInformationText ~ reportBugsText
            );

        return (this.value[0] ? true : false);
    }

    /**
        Encodes a boolean.

        Any non-zero value will be interpreted as TRUE. Only zero will be
        interpreted as FALSE.
    */
    override public @property @safe nothrow
    void boolean(in bool value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        this.value = [(value ? 0xFFu : 0x00u)];
    }

    ///
    @safe
    unittest
    {
        BERElement bv = new BERElement();
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
    T integer(T)() const
    if (isIntegral!T && isSigned!T)
    {
        if (this.value.length == 0u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode an " ~
                "INTEGER that was encoded on 0 bytes. According to the Basic " ~
                "Encoding Rules (BER), an INTEGER must be encoded on at least " ~
                "one byte. Even 0 must be encoded as a single null byte. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        if (this.value.length == 1u)
            return cast(T) cast(byte) this.value[0];

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

        if
        (
            this.value.length > 1u &&
            (
                (this.value[0] == 0x00u && (!(this.value[1] & 0x80u))) || // Unnecessary positive leading bytes
                (this.value[0] == 0xFFu && (this.value[1] & 0x80u)) // Unnecessary negative leading bytes
            )
        )
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode " ~
                "an INTEGER that was encoded on more than the minimum " ~
                "necessary bytes. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

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
        immutable ubyte paddingByte = ((this.value[0] & 0x80u) ? 0xFFu : 0x00u);
        while (value.length < T.sizeof)
            value = (paddingByte ~ value);
        version (LittleEndian) reverse(value);
        version (unittest) assert(value.length == T.sizeof);
        return *cast(T *) value.ptr;
    }

    /**
        Encodes an integer.

        Bytes are stored in big-endian order, where the bytes represent
        the two's complement encoding of the integer.
    */
    public @property @system nothrow
    void integer(T)(in T value)
    if (isIntegral!T && isSigned!T)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        if (value <= byte.max && value >= byte.min)
        {
            this.value = [ cast(ubyte) cast(byte) value ];
            return;
        }

        ubyte[] ub;
        ub.length = T.sizeof;
        *cast(T *)&ub[0] = value;
        version (LittleEndian) reverse(ub);

        /*
            An INTEGER must be encoded on the fewest number of bytes than can
            encode it. The loops below identify how many bytes can be
            truncated from the start of the INTEGER, with one loop for positive
            and another loop for negative numbers.

            From X.690, Section 8.3.2:

            If the contents octets of an integer value encoding consist of more
            than one octet, then the bits of the first octet and bit 8 of the
            second octet:
                a) shall not all be ones; and
                b) shall not all be zero.
                NOTE – These rules ensure that an integer value is always
                encoded in the smallest possible number of octets.
        */
        size_t startOfNonPadding = 0u;
        if (T.sizeof > 1u)
        {
            if (value >= 0)
            {
                for (size_t i = 0u; i < ub.length-1; i++)
                {
                    if (ub[i] != 0x00u) break;
                    if (!(ub[i+1] & 0x80u)) startOfNonPadding++;
                }
            }
            else
            {
                for (size_t i = 0u; i < ub.length-1; i++)
                {
                    if (ub[i] != 0xFFu) break;
                    if (ub[i+1] & 0x80u) startOfNonPadding++;
                }
            }
        }

        this.value = ub[startOfNonPadding .. $];
    }

    // Ensure that INTEGER 0 gets encoded on a single null byte.
    @system
    unittest
    {
        BERElement el = new BERElement();

        el.integer!byte = cast(byte) 0x00;
        assert(el.value == [ 0x00u ]);

        el.integer!short = cast(short) 0x0000;
        assert(el.value == [ 0x00u ]);

        el.integer!int = cast(int) 0;
        assert(el.value == [ 0x00u ]);

        el.integer!long = cast(long) 0;
        assert(el.value == [ 0x00u ]);

        el.value = [];
        assertThrown!ASN1ValueInvalidException(el.integer!byte);
        assertThrown!ASN1ValueInvalidException(el.integer!short);
        assertThrown!ASN1ValueInvalidException(el.integer!int);
        assertThrown!ASN1ValueInvalidException(el.integer!long);
    }

    // Test encoding -0 for the sake of CVE-2016-2108
    @system
    unittest
    {
        BERElement el = new BERElement();

        el.integer!byte = -0;
        assertNotThrown!RangeError(el.integer!byte);
        assertNotThrown!ASN1Exception(el.integer!byte);

        el.integer!short = -0;
        assertNotThrown!RangeError(el.integer!short);
        assertNotThrown!ASN1Exception(el.integer!short);

        el.integer!int = -0;
        assertNotThrown!RangeError(el.integer!int);
        assertNotThrown!ASN1Exception(el.integer!int);

        el.integer!long = -0;
        assertNotThrown!RangeError(el.integer!long);
        assertNotThrown!ASN1Exception(el.integer!long);
    }

    /**
        Encodes an array of $(D bool)s representing a string of bits.

        In Basic Encoding Rules, the first byte is an unsigned
        integral byte indicating the number of unused bits at the end of
        the BIT STRING. The unused bits can be anything.

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
                "In Basic Encoding Rules, the first byte of the encoded " ~
                "binary value (after the type and length bytes, of course) " ~
                "is used to indicate how many unused bits there are at the " ~
                "end of the BIT STRING. Since everything is encoded in bytes " ~
                "in Basic Encoding Rules, but a BIT STRING may not " ~
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

        if (this.value[0] > 0x00u && this.value.length <= 1u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode a " ~
                "BIT STRING that had a misleading first byte, which indicated " ~
                "that there were more than zero padding bits, but there were " ~
                "no subsequent octets supplied, which contain the octet-" ~
                "aligned bits and padding. This may have been a mistake on " ~
                "the part of the encoder, but this looks really suspicious: " ~
                "it is likely that an attempt was made to hack your systems " ~
                "by inducing an out-of-bounds read from an array. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        bool[] ret;
        for (size_t i = 1; i < this.value.length; i++)
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

        In Basic Encoding Rules, the first byte is an unsigned
        integral byte indicating the number of unused bits at the end of
        the BIT STRING. The unused bits can be anything.
    */
    override public @property
    void bitString(in bool[] value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        ubyte[] ub;
        ub.length = ((value.length / 8u) + (value.length % 8u ? 1u : 0u));
        for (size_t i = 0u; i < value.length; i++)
        {
            if (value[i] == false) continue;
            ub[(i/8u)] |= (0b1000_0000u >> (i % 8u));
        }
        this.value = [ cast(ubyte) (8u - (value.length % 8u)) ] ~ ub;
        if (this.value[0] == 0x08u) this.value[0] = 0x00u;
    }

    // Test a BIT STRING with a deceptive first byte.
    @system
    unittest
    {
        BERElement el = new BERElement();
        el.value = [ 0x01u ];
        assertThrown!ASN1ValueInvalidException(el.bitString);
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
    void octetString(in ubyte[] value)
    {
        this.value = value.dup;
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
        assert(value.length >= 2u);
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

        if (this.value.length >= 2u)
        {
            // Skip the first, because it is fine if it is 0x80
            // Skip the last because it will be checked next
            foreach (immutable octet; this.value[1 .. $-1])
            {
                if (octet == 0x80u)
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you attempted to decode " ~
                        "an OBJECT IDENTIFIER that contained a number that was " ~
                        "encoded on more than the minimum necessary octets. This " ~
                        "is indicated by an occurrence of the octet 0x80, which " ~
                        "is the encoded equivalent of a leading zero. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );
            }

            if ((this.value[$-1] & 0x80u) == 0x80u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an OBJECT IDENTIFIER whose last byte had the most significant " ~
                    "bit set, which is used to indicate the continuity of the " ~
                    "encoding of a number on the next octet. In other words, the " ~
                    "encoded data appears to be truncated. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
        }

        size_t[] numbers;
        if (this.value[0] >= 0x50u)
        {
            numbers = [ 2u, (this.value[0] - 0x50u) ];
        }
        else if (this.value[0] >= 0x28u)
        {
            numbers = [ 1u, (this.value[0] - 0x28u) ];
        }
        else
        {
            numbers = [ 0u, this.value[0] ];
        }

        // Breaks bytes into groups, where each group encodes one OID component.
        ubyte[][] byteGroups;
        size_t lastTerminator = 1;
        for (size_t i = 1; i < this.length; i++)
        {
            if (!(this.value[i] & 0x80u))
            {
                byteGroups ~= cast(ubyte[]) this.value[lastTerminator .. i+1];
                lastTerminator = i+1;
            }
        }

        // Converts each group of bytes to a number.
        foreach (const byteGroup; byteGroups)
        {
            if (byteGroup.length > size_t.sizeof)
                throw new ASN1ValueTooBigException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a OBJECT IDENTIFIER that encoded a number on more than " ~
                    "size_t bytes. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );

            numbers ~= 0u;
            for (size_t i = 0u; i < byteGroup.length; i++)
            {
                numbers[$-1] <<= 7;
                numbers[$-1] |= cast(size_t) (byteGroup[i] & 0x7Fu);
            }
        }

        // Constructs the array of OIDNodes from the array of numbers.
        OIDNode[] nodes;
        foreach (number; numbers)
        {
            nodes ~= OIDNode(number);
        }

        return new OID(nodes);
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
    void objectIdentifier(in OID value)
    in
    {
        assert(value.length >= 2u);
        assert(value.numericArray[0] <= 2u);
        if (value.numericArray[0] == 2u)
            assert(value.numericArray[1] <= 175u);
        else
            assert(value.numericArray[1] <= 39u);
    }
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        size_t[] numbers = value.numericArray();
        this.value = [ cast(ubyte) (numbers[0] * 40u + numbers[1]) ];
        if (numbers.length > 2u)
        {
            foreach (number; numbers[2 .. $])
            {
                if (number < 128u)
                {
                    this.value ~= cast(ubyte) number;
                    continue;
                }

                ubyte[] encodedOIDNode;
                while (number != 0u)
                {
                    ubyte[] numberBytes;
                    numberBytes.length = size_t.sizeof;
                    *cast(size_t *) numberBytes.ptr = number;
                    if ((numberBytes[0] & 0x80u) == 0u) numberBytes[0] |= 0x80u;
                    encodedOIDNode = numberBytes[0] ~ encodedOIDNode;
                    number >>= 7u;
                }

                encodedOIDNode[$-1] &= 0x7Fu;
                this.value ~= encodedOIDNode;
            }
        }
    }

    @system
    unittest
    {
        BERElement element = new BERElement();

        // All values of octet[0] should pass.
        for (ubyte i = 0x00u; i < 0xFFu; i++)
        {
            element.value = [ i ];
            assertNotThrown!Exception(element.objectIdentifier);
        }

        // All values of octet[0] should pass.
        for (ubyte i = 0x00u; i < 0xFFu; i++)
        {
            element.value = [ i, 0x14u ];
            assertNotThrown!Exception(element.objectIdentifier);
        }
    }

    @system
    unittest
    {
        BERElement element = new BERElement();

        // Tests for the "leading zero byte," 0x80
        element.value = [ 0x29u, 0x80u ];
        assertThrown!ASN1ValueInvalidException(element.objectIdentifier);
        element.value = [ 0x29u, 0x80u, 0x14u ];
        assertThrown!ASN1ValueInvalidException(element.objectIdentifier);
        element.value = [ 0x29u, 0x14u, 0x80u ];
        assertThrown!ASN1ValueInvalidException(element.objectIdentifier);
        element.value = [ 0x29u, 0x80u, 0x80u ];
        assertThrown!ASN1ValueInvalidException(element.objectIdentifier);
        element.value = [ 0x80u, 0x80u, 0x80u ];
        assertThrown!ASN1ValueInvalidException(element.objectIdentifier);

        // Test for non-terminating components
        element.value = [ 0x29u, 0x81u ];
        assertThrown!ASN1ValueInvalidException(element.objectIdentifier);
        element.value = [ 0x29u, 0x14u, 0x81u ];
        assertThrown!ASN1ValueInvalidException(element.objectIdentifier);

        // This one should not fail. 0x80u is valid for the first octet.
        element.value = [ 0x80u, 0x14u, 0x14u ];
        assertNotThrown!ASN1ValueInvalidException(element.objectIdentifier);
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
        foreach (immutable character; this.value)
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
    void objectDescriptor(in string value)
    {
        foreach (immutable character; value)
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

        EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
            direct-reference  OBJECT IDENTIFIER OPTIONAL,
            indirect-reference  INTEGER OPTIONAL,
            data-value-descriptor  ObjectDescriptor  OPTIONAL,
            encoding  CHOICE {
                single-ASN1-type  [0] ANY,
                octet-aligned     [1] IMPLICIT OCTET STRING,
                arbitrary         [2] IMPLICIT BIT STRING } }
    */
    deprecated override public @property @system
    External external() const
    {
        const BERElement[] components = this.sequence;
        External ext = External();
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length < 2u || components.length > 4u)
            throw new ASN1ValueSizeException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EXTERNAL that contained too many or too few elements. " ~
                "An EXTERNAL should have between two and four elements: " ~
                "either a direct-reference (syntax) and/or an indirect-" ~
                "reference (presentation-context-id), an optional " ~
                "data-value-descriptor, and an encoding (data-value). " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        // Every component except the last must be universal class
        foreach (const component; components[0 .. $-1])
        {
            if (component.tagClass != ASN1TagClass.universal)
                throw new ASN1TagException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an EXTERNAL whose components were not of the correct tag " ~
                    "class. When using Basic Encoding Rules, all but the last " ~
                    "component of the encoded EXTERNAL must be of UNIVERSAL " ~
                    "class. The last component must be of CONTEXT SPECIFIC " ~
                    "class. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
        }

        // The last tag must be context-specific class
        if (components[$-1].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EXTERNAL whose last component was not of the correct tag " ~
                "class. When using Basic Encoding Rules, all but the last " ~
                "component of the encoded EXTERNAL must be of UNIVERSAL " ~
                "class. The last component must be of CONTEXT SPECIFIC " ~
                "class. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        // The first component should always be primitive
        if (components[0].construction != ASN1Construction.primitive)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EXTERNAL whose first element was not primitively " ~
                "constructed. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        if
        (
            components[0].tagNumber != ASN1UniversalType.objectIdentifier &&
            components[0].tagNumber != ASN1UniversalType.integer
        )
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EXTERNAL whose first component was not an INTEGER or " ~
                "OBJECT IDENTIFIER. The first component of an EXTERNAL " ~
                "must be either an OBJECT IDENTIFIER or an INTEGER if it is " ~
                "encoded using Basic Encoding Rules. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        switch (components.length)
        {
            case (2u):
            {
                if (components[0].tagNumber == ASN1UniversalType.objectIdentifier)
                    identification.directReference = components[0].objectIdentifier;
                else
                    identification.indirectReference = components[0].integer!ptrdiff_t;
                break;
            }
            case (3u):
            {
                if
                (
                    components[0].tagNumber == ASN1UniversalType.objectIdentifier &&
                    components[1].tagNumber == ASN1UniversalType.integer
                )
                {
                    if (components[1].construction != ASN1Construction.primitive)
                        throw new ASN1ValueInvalidException
                        (
                            "This exception was thrown because you attempted to " ~
                            "decode an EXTERNAL whose second element out of " ~
                            "three was primitively constructed. Whether it is " ~
                            "an OBJECT IDENTIFIER or an ObjectDescriptor, it " ~
                            "must be primitively constructed. " ~
                            notWhatYouMeantText ~ forMoreInformationText ~
                            debugInformationText ~ reportBugsText
                        );

                    identification.contextNegotiation = ASN1ContextNegotiation(
                        components[1].integer!ptrdiff_t,
                        components[0].objectIdentifier
                    );
                }
                else if (components[1].tagNumber == ASN1UniversalType.objectDescriptor)
                {
                    if (components[0].tagNumber == ASN1UniversalType.objectIdentifier)
                        identification.directReference = components[0].objectIdentifier;
                    else
                        identification.indirectReference = components[0].integer!ptrdiff_t;

                    if (components[1].construction == ASN1Construction.primitive)
                    {
                        ext.dataValueDescriptor = components[1].objectDescriptor;
                    }
                    else
                    {
                        Appender!string descriptor = appender!string();
                        BERElement[] substrings = components[1].sequence;
                        foreach (substring; substrings)
                        {
                            descriptor.put(substring.objectDescriptor);
                        }
                        ext.dataValueDescriptor = descriptor.data;
                    }
                }
                else
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you attempted to decode " ~
                        "an EXTERNAL whose middle component was neither an OBJECT " ~
                        "IDENTIFIER, INTEGER, nor ObjectDescriptor. This middle " ~
                        "component of the three must be one of those types. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );
                break;
            }
            case (4u):
            {
                if
                (
                    components[0].tagNumber != ASN1UniversalType.objectIdentifier ||
                    components[1].tagNumber != ASN1UniversalType.integer ||
                    components[2].tagNumber != ASN1UniversalType.objectDescriptor
                )
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you attempted to decode " ~
                        "an external whose components were either misordered or " ~
                        "not of the correct type. When encoding an EXTERNAL using " ~
                        "the Basic Encoding Rules, and encoding context-" ~
                        "negotiation, and encoding a data-value-descriptor, " ~
                        "the resulting EXTERNAL should contain four components, " ~
                        "and the first three should have the types OBJECT " ~
                        "IDENTIFIER, INTEGER, and ObjectDescriptor in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                if (components[1].construction != ASN1Construction.primitive)
                    throw new ASN1TagException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EXTERNAL whose second element was not " ~
                        "primitively constructed, despite being INTEGER type. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                identification.contextNegotiation = ASN1ContextNegotiation(
                    components[1].integer!ptrdiff_t,
                    components[0].objectIdentifier
                );

                if (components[2].construction == ASN1Construction.primitive)
                {
                    ext.dataValueDescriptor = components[2].objectDescriptor;
                }
                else
                {
                    Appender!string descriptor = appender!string();
                    BERElement[] substrings = components[2].sequence;
                    foreach (substring; substrings)
                    {
                        descriptor.put(substring.objectDescriptor);
                    }
                    ext.dataValueDescriptor = descriptor.data;
                }
                break;
            }
            default:
            {
                assert(0, "Impossible EXTERNAL length occurred!");
            }
        }

        switch (components[$-1].tagNumber)
        {
            case (0u): // single-ASN1-value
            {
                ext.encoding = ASN1ExternalEncodingChoice.singleASN1Type;
                break;
            }
            case (1u): // octet-aligned
            {
                ext.encoding = ASN1ExternalEncodingChoice.octetAligned;
                break;
            }
            case (2u): // arbitrary
            {
                ext.encoding = ASN1ExternalEncodingChoice.arbitrary;
                break;
            }
            default:
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an EXTERNAL that was encoded according to the pre-1994 " ~
                    "specification (as required by the ITU's X.690 " ~
                    "specification), but used an invalid choice for the encoding " ~
                    "component. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
        }

        ext.dataValue = components[$-1].value.dup;
        ext.identification = identification;
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
            ASN1ValueInvalidException = if encoded ObjectDescriptor contains
                invalid characters.

        EXTERNAL  ::=  [UNIVERSAL 8] IMPLICIT SEQUENCE {
            direct-reference  OBJECT IDENTIFIER OPTIONAL,
            indirect-reference  INTEGER OPTIONAL,
            data-value-descriptor  ObjectDescriptor  OPTIONAL,
            encoding  CHOICE {
                single-ASN1-type  [0] ANY,
                octet-aligned     [1] IMPLICIT OCTET STRING,
                arbitrary         [2] IMPLICIT BIT STRING } }
    */
    deprecated override public @property @system
    void external(in External value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        BERElement[] components = [];

        if (!(value.identification.syntax.isNull))
        {
            BERElement directReference = new BERElement();
            directReference.tagNumber = ASN1UniversalType.objectIdentifier;
            directReference.objectIdentifier = value.identification.directReference;
            components ~= directReference;
        }
        else if (!(value.identification.contextNegotiation.isNull))
        {
            BERElement directReference = new BERElement();
            directReference.tagNumber = ASN1UniversalType.objectIdentifier;
            directReference.objectIdentifier = value.identification.contextNegotiation.directReference;
            components ~= directReference;

            BERElement indirectReference = new BERElement();
            indirectReference.tagNumber = ASN1UniversalType.integer;
            indirectReference.integer!ptrdiff_t = cast(ptrdiff_t) value.identification.contextNegotiation.indirectReference;
            components ~= indirectReference;
        }
        else // it must be the presentationContextID / indirectReference INTEGER
        {
            BERElement indirectReference = new BERElement();
            indirectReference.tagNumber = ASN1UniversalType.integer;
            indirectReference.integer!ptrdiff_t = value.identification.indirectReference;
            components ~= indirectReference;
        }

        BERElement dataValueDescriptor = new BERElement();
        dataValueDescriptor.tagNumber = ASN1UniversalType.objectDescriptor;
        dataValueDescriptor.objectDescriptor = value.dataValueDescriptor;
        components ~= dataValueDescriptor;

        BERElement dataValue = new BERElement();
        dataValue.tagClass = ASN1TagClass.contextSpecific;
        dataValue.tagNumber = value.encoding;
        dataValue.value = value.dataValue.dup;

        components ~= dataValue;
        this.sequence = components;
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element, because Distinguished
        Encoding Rules (DER) does not permit EXTERNALs to use an identification
        CHOICE of presentation-context-id or context-negotiation
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

        BERElement el = new BERElement();
        el.external = input;
        External output = el.external;
        assert(output.identification.presentationContextID == 27L);
        assert(output.dataValueDescriptor == "external");
        assert(output.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]);
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element, because Distinguished
        Encoding Rules (DER) does not permit EXTERNALs to use an identification
        CHOICE of presentation-context-id or context-negotiation
    */
    @system
    unittest
    {
        ASN1ContextNegotiation cn = ASN1ContextNegotiation();
        cn.presentationContextID = 27L;
        cn.transferSyntax = new OID(1, 3, 6, 4, 1, 256, 39);

        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.contextNegotiation = cn;

        External input = External();
        input.identification = id;
        input.dataValueDescriptor = "blap";
        input.dataValue = [ 0x13u, 0x15u, 0x17u, 0x19u ];

        BERElement el = new BERElement();
        el.external = input;
        External output = el.external;
        assert(output.identification.contextNegotiation.presentationContextID == 27L);
        assert(output.identification.contextNegotiation.transferSyntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.dataValueDescriptor == "blap");
        assert(output.dataValue == [ 0x13u, 0x15u, 0x17u, 0x19u ]);

        // Assert that accessor does not mutate state
        assert(el.external == el.external);
    }

    // Inspired by CVE-2017-9023
    @system
    unittest
    {
        ubyte[] external = [ // This is valid
            0x08u, 0x09u, // EXTERNAL, Length 9
                0x02u, 0x01u, 0x1Bu, // INTEGER 27
                0x81, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];

        // Valid values for octet[2]: 02 06
        for (ubyte i = 0x07u; i < 0x1Eu; i++)
        {
            external[2] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, external);
            assertThrown!ASN1ValueInvalidException(el.external);
        }

        // Valid values for octet[5]: 80 - 82 (Anything else is an invalid value)
        for (ubyte i = 0x82u; i < 0x9Eu; i++)
        {
            external[5] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, external);
            assertThrown!ASN1ValueInvalidException(el.external);
        }
    }

    // Assert that duplicate elements throw exceptions
    @system
    unittest
    {
        ubyte[] external;

        external = [ // This is invalid
            0x08u, 0x0Cu, // EXTERNAL, Length 12
                0x02u, 0x01u, 0x1Bu, // INTEGER 27
                0x02u, 0x01u, 0x1Bu, // INTEGER 27
                0x81, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];
        assertThrown!ASN1Exception((new BERElement(external)).external);

        external = [ // This is invalid
            0x08u, 0x0Eu, // EXTERNAL, Length 14
                0x06u, 0x02u, 0x2Au, 0x03u, // OBJECT IDENTIFIER 1.2.3
                0x06u, 0x02u, 0x2Au, 0x03u, // OBJECT IDENTIFIER 1.2.3
                0x81, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];
        assertThrown!ASN1Exception((new BERElement(external)).external);

        external = [ // This is invalid
            0x08u, 0x12u, // EXTERNAL, Length 18
                0x06u, 0x02u, 0x2Au, 0x03u, // OBJECT IDENTIFIER 1.2.3
                0x07u, 0x02u, 0x45u, 0x45u, // ObjectDescriptor "EE"
                0x07u, 0x02u, 0x45u, 0x45u, // ObjectDescriptor "EE"
                0x81u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];
        assertThrown!ASN1Exception((new BERElement(external)).external);

        external = [ // This is invalid
            0x08u, 0x14u, // EXTERNAL, Length 20
                0x06u, 0x02u, 0x2Au, 0x03u, // OBJECT IDENTIFIER 1.2.3
                0x07u, 0x02u, 0x45u, 0x45u, // ObjectDescriptor "EE"
                0x81u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u, // OCTET STRING 1,2,3,4
                0x81u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];
        assertThrown!ASN1Exception((new BERElement(external)).external);
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
            ASN1ValueInvalidException = if both bits indicating the base in the
                information byte of a binary-encoded REAL's information byte
                are set, which would indicate an invalid base.

        Citations:
            Dubuisson, Olivier. “Basic Encoding Rules (BER).” ASN.1:
            Communication between Heterogeneous Systems, Morgan Kaufmann,
            2001, pp. 400–402.
    */
    public @property @system
    T realType(T)() const
    if (is(T == float) || is(T == double))
    {
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
                import std.conv : to;
                return to!(T)(cast(string) this.value[1 .. $]);
            }
            case 0b_1000_0000u, 0b_1100_0000u: // Binary Encoding
            {
                ulong mantissa;
                short exponent;
                ubyte scale;
                ubyte base;
                size_t startOfMantissa;

                switch (this.value[0] & 0b00000011u)
                {
                    case 0b00000000u: // Exponent on the following octet
                    {
                        if (this.length < 2u)
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

                        exponent = cast(short) cast(byte) this.value[1];
                        startOfMantissa = 2u;
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
                        exponent = *cast(short *) exponentBytes.ptr;
                        startOfMantissa = 3u;
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

                        ubyte[] exponentBytes = this.value[1 .. 4].dup;

                        if // the first byte is basically meaningless padding
                        (
                            (this.value[0] == 0x00u && (!(this.value[1] & 0x80u))) || // Unnecessary positive leading bytes
                            (this.value[0] == 0xFFu && (this.value[1] & 0x80u)) // Unnecessary negative leading bytes
                        )
                        { // then it is small enough to become an IEEE 754 floating point type.
                            exponentBytes = exponentBytes[1 .. $];
                            exponent = *cast(short *) exponentBytes.ptr;
                            startOfMantissa = 4u;
                        }
                        else
                        {
                            throw new ASN1ValueTooBigException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL that had an exponent that was " ~
                                "too big to decode to a floating-point type." ~
                                "Specifically, the exponent was encoded on " ~
                                "more than two bytes, which is simply too " ~
                                "many to fit in any IEEE 754 Floating Point " ~
                                "type supported by this system. " ~
                                notWhatYouMeantText ~ forMoreInformationText ~
                                debugInformationText ~ reportBugsText
                            );
                        }
                        break;
                    }
                    case 0b00000011: // Complicated
                    {
                        /* NOTE:
                            X.690 states that, in this case, the exponent must
                            be encoded on the fewest possible octets, even for
                            the Basic Encoding Rules (BER).
                        */

                        if (this.length < 3u)
                            throw new ASN1ValueTooSmallException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL that had too few bytes. The first " ~
                                "byte indicated that the subsequent byte " ~
                                "would encode the length of the exponent of the REAL, but " ~
                                "there were less than three bytes in the entire " ~
                                "encoded value. There must be a first byte for " ~
                                "information, a second byte for the exponent length " ~
                                "then the exponent cannot be a zero, so it must " ~
                                "be encoded on at least one byte. " ~
                                notWhatYouMeantText ~ forMoreInformationText ~
                                debugInformationText ~ reportBugsText
                            );

                        immutable ubyte exponentLength = this.value[1];

                        if (exponentLength == 0u)
                            throw new ASN1ValueInvalidException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL whose exponent was encoded on " ~
                                "zero bytes, which is prohibited by the X.690 " ~
                                "specification, section 8.5.6.4, note D. "
                            );

                        if (exponentLength > (this.length + 2u))
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

                        if (exponentLength > 2u)
                            throw new ASN1ValueTooBigException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL that had an exponent that was " ~
                                "too big to decode to a floating-point type." ~
                                "Specifically, the exponent was encoded on " ~
                                "more than two bytes, which is simply too " ~
                                "many to fit in any IEEE 754 Floating Point " ~
                                "type supported by this system. " ~
                                notWhatYouMeantText ~ forMoreInformationText ~
                                debugInformationText ~ reportBugsText
                            );

                        if (exponentLength == 1u)
                        {
                            exponent = cast(short) cast(byte) this.value[2];
                        }
                        else // length == 2
                        {
                            ubyte[] exponentBytes = this.value[2 .. 4].dup;

                            if
                            (
                                (exponentBytes[0] == 0x00u && (!(exponentBytes[1] & 0x80u))) || // Unnecessary positive leading bytes
                                (exponentBytes[0] == 0xFFu && (exponentBytes[1] & 0x80u)) // Unnecessary negative leading bytes
                            )
                                throw new ASN1ValueInvalidException
                                (
                                    "This exception was thrown because you attempted to decode " ~
                                    "a REAL exponent that was encoded on more than the minimum " ~
                                    "necessary bytes. " ~
                                    notWhatYouMeantText ~ forMoreInformationText ~
                                    debugInformationText ~ reportBugsText
                                );

                            version (LittleEndian) reverse(exponentBytes);
                            exponent = *cast(short *) exponentBytes.ptr;
                        }
                        startOfMantissa = (2u + exponentLength);
                        break;
                    }
                    default: assert(0, "Impossible binary exponent encoding on REAL type");
                }

                if (this.value.length - startOfMantissa > 8u)
                    throw new ASN1ValueTooBigException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a REAL whose mantissa was encoded on too many " ~
                        "bytes to decode to the largest unsigned integral data " ~
                        "type. "
                    );

                ubyte[] mantissaBytes = this.value[startOfMantissa .. $].dup;
                immutable ubyte paddingByte = ((mantissaBytes[0] & 0x80u) ? 0xFFu : 0x00u);
                while (mantissaBytes.length < ulong.sizeof)
                    mantissaBytes = (paddingByte ~ mantissaBytes);
                version (LittleEndian) reverse(mantissaBytes);
                version (unittest) assert(mantissaBytes.length == ulong.sizeof);
                mantissa = *cast(ulong *) mantissaBytes.ptr;

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

                scale = ((this.value[0] & 0b_0000_1100u) >> 2);

                /*
                    For some reason that I have yet to discover, you must
                    cast the exponent to T. If you do not, specifically
                    any usage of realType!T() outside of this library will
                    produce a "floating point exception 8" message and
                    crash. For some reason, all of the tests pass within
                    this library without doing this.
                */
                return (
                    ((this.value[0] & 0b_0100_0000u) ? -1.0 : 1.0) *
                    cast(T) mantissa *
                    2^^scale *
                    (cast(T) base)^^(cast(T) exponent) // base must be cast
                );
            }
            default: assert(0, "Impossible information byte value appeared!");
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
            ASN1ValueInvalidException = if an attempt to encode NaN is made.
            ASN1ValueTooSmallException = if an attempt to encode would result
                in an arithmetic underflow of a signed short.
            ASN1ValueTooBigException = if an attempt to encode would result
                in an arithmetic overflow of a signed short.

        Citations:
            Dubuisson, Olivier. “Basic Encoding Rules (BER).” ASN.1:
            Communication between Heterogeneous Systems, Morgan Kaufmann,
            2001, pp. 400–402.
    */
    public @property @system
    void realType(T)(in T value)
    if (is(T == float) || is(T == double))
    {
        import std.bitmanip : DoubleRep, FloatRep;
        bool positive = true;
        ulong significand;
        short exponent = 0;

        if (value == 0.0)
        {
            this.value = [];
            return;
        }
        else if (value.isNaN)
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
            immutable DoubleRep valueUnion = DoubleRep(value);
            significand = (valueUnion.fraction | 0x0010000000000000u); // Flip bit #53
        }
        static if (is(T == float))
        {
            immutable FloatRep valueUnion = FloatRep(value);
            significand = (valueUnion.fraction | 0x00800000u); // Flip bit #24
        }

        positive = (valueUnion.sign ? false : true);
        exponent = cast(short) (valueUnion.exponent - valueUnion.bias - valueUnion.fractionBits);

        ubyte[] exponentBytes;
        exponentBytes.length = short.sizeof;
        *cast(short *)exponentBytes.ptr = exponent;
        version (LittleEndian) exponentBytes = [ exponentBytes[1], exponentBytes[0] ]; // Manual reversal (optimization)
        if
        (
            (exponentBytes[0] == 0x00u && (!(exponentBytes[1] & 0x80u))) || // Unnecessary positive leading bytes
            (exponentBytes[0] == 0xFFu && (exponentBytes[1] & 0x80u)) // Unnecessary negative leading bytes
        )
            exponentBytes = exponentBytes[1 .. 2];

        ubyte[] significandBytes;
        significandBytes.length = ulong.sizeof;
        *cast(ulong *)significandBytes.ptr = cast(ulong) significand;
        version (LittleEndian) reverse(significandBytes);

        size_t startOfNonPadding = 0u;
        if (significand >= 0)
        {
            for (size_t i = 0u; i < significandBytes.length-1; i++)
            {
                if (significandBytes[i] != 0x00u) break;
                if (!(significandBytes[i+1] & 0x80u)) startOfNonPadding++;
            }
        }
        else
        {
            for (size_t i = 0u; i < significandBytes.length-1; i++)
            {
                if (significandBytes[i] != 0xFFu) break;
                if (significandBytes[i+1] & 0x80u) startOfNonPadding++;
            }
        }
        significandBytes = significandBytes[startOfNonPadding .. $];

        ubyte infoByte =
            0x80u | // First bit gets set for base2, base8, or base16 encoding
            (positive ? 0x00u : 0x40u) | // 1 = negative, 0 = positive
            // Scale = 0
            cast(ubyte) (exponentBytes.length == 1u ?
                ASN1RealExponentEncoding.followingOctet :
                ASN1RealExponentEncoding.following2Octets);

        this.value = (infoByte ~ exponentBytes ~ significandBytes);
    }

    // Testing Base-10 (Character-Encoded) REALs
    // @system
    // unittest
    // {
    //     BERElement el = new BERElement();
    //     BERElement.realEncodingBase = ASN1RealEncodingBase.base10;

    //     // Test that the exponent gets a + sign if it is 0.
    //     el.realType!float = 2.2;
    //     assert(cast(string) (el.value[1 .. $]) == "2.200000E+0");
    //     assert(approxEqual(el.realType!float, 2.2));
    //     assert(approxEqual(el.realType!double, 2.2));
    //     el.realType!double = 2.2;
    //     assert(cast(string) (el.value[1 .. $]) == "2.200000000000E+0");
    //     assert(approxEqual(el.realType!float, 2.2));
    //     assert(approxEqual(el.realType!double, 2.2));

    //     // Decimal + trailing zeros are not added if not necessary.
    //     el.realType!float = 22.0;
    //     assert(cast(string) (el.value[1 .. $]) == "2.200000E1");
    //     assert(approxEqual(el.realType!float, 22.0));
    //     assert(approxEqual(el.realType!double, 22.0));
    //     el.realType!double = 22.0;
    //     assert(cast(string) (el.value[1 .. $]) == "2.200000000000E1");
    //     assert(approxEqual(el.realType!float, 22.0));
    //     assert(approxEqual(el.realType!double, 22.0));

    //     // Decimal + trailing zeros are added if necessary.
    //     el.realType!float = 22.123;
    //     assert(cast(string) (el.value[1 .. $]) == "2.212300E1");
    //     assert(approxEqual(el.realType!float, 22.123));
    //     assert(approxEqual(el.realType!double, 22.123));
    //     el.realType!double = 22.123;
    //     assert(cast(string) (el.value[1 .. $]) == "2.212300000000E1");
    //     assert(approxEqual(el.realType!float, 22.123));
    //     assert(approxEqual(el.realType!double, 22.123));

    //     // Negative numbers are encoded correctly.
    //     el.realType!float = -22.123;
    //     assert(cast(string) (el.value[1 .. $]) == "-2.212300E1");
    //     assert(approxEqual(el.realType!float, -22.123));
    //     assert(approxEqual(el.realType!double, -22.123));
    //     el.realType!double = -22.123;
    //     assert(cast(string) (el.value[1 .. $]) == "-2.212300000000E1");
    //     assert(approxEqual(el.realType!float, -22.123));
    //     assert(approxEqual(el.realType!double, -22.123));

    //     // Small positive numbers are encoded correctly.
    //     el.realType!float = 0.123;
    //     assert(cast(string) (el.value[1 .. $]) == "1.230000E-1");
    //     assert(approxEqual(el.realType!float, 0.123));
    //     assert(approxEqual(el.realType!double, 0.123));
    //     el.realType!double = 0.123;
    //     assert(cast(string) (el.value[1 .. $]) == "1.230000000000E-1");
    //     assert(approxEqual(el.realType!float, 0.123));
    //     assert(approxEqual(el.realType!double, 0.123));

    //     // Small negative numbers are encoded correctly.
    //     el.realType!float = -0.123;
    //     assert(cast(string) (el.value[1 .. $]) == "-1.230000E-1");
    //     assert(approxEqual(el.realType!float, -0.123));
    //     assert(approxEqual(el.realType!double, -0.123));
    //     el.realType!double = -0.123;
    //     assert(cast(string) (el.value[1 .. $]) == "-1.230000000000E-1");
    //     assert(approxEqual(el.realType!float, -0.123));
    //     assert(approxEqual(el.realType!double, -0.123));

    //     BERElement.realEncodingBase = ASN1RealEncodingBase.base2;
    // }

    // Test "complicated" exponent encoding.
    // @system
    // unittest
    // {
    //     BERElement el = new BERElement();

    //     el.value = [ 0b1000_0011u, 0x01u, 0x00u, 0x03u ];
    //     assert(el.realType!float == 3.0);
    //     assert(el.realType!double == 3.0);

    //     el.value = [ 0b1000_0011u, 0x01u, 0x05u, 0x03u ];
    //     assert(el.realType!float == 96.0);
    //     assert(el.realType!double == 96.0);

    //     el.value = [ 0b1000_0011u, 0x02u, 0x00u, 0x05u, 0x03u ];
    //     assert(el.realType!float == 96.0);
    //     assert(el.realType!double == 96.0);

    //     el.value = [ 0b1000_0011u ];
    //     el.value ~= cast(ubyte) size_t.sizeof;
    //     el.value.length += size_t.sizeof;
    //     el.value[$-1] = 0x05u;
    //     el.value ~= 0x03u;
    //     assert(el.realType!float == 96.0);
    //     assert(el.realType!double == 96.0);
    // }

    /**
        Decodes an integer from an ENUMERATED type. In BER, an ENUMERATED
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
        if (this.value.length == 0u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode an " ~
                "ENUMERATED that was encoded on 0 bytes. According to the Basic " ~
                "Encoding Rules (BER), an ENUMERATED must be encoded on at least " ~
                "one byte. Even 0 must be encoded as a single null byte. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        if (this.value.length == 1u)
            return cast(T) cast(byte) this.value[0];

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

        if
        (
            this.value.length > 1u &&
            (
                (this.value[0] == 0x00u && (!(this.value[1] & 0x80u))) || // Unnecessary positive leading bytes
                (this.value[0] == 0xFFu && (this.value[1] & 0x80u)) // Unnecessary negative leading bytes
            )
        )
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode " ~
                "an ENUMERATED that was encoded on more than the minimum " ~
                "necessary bytes. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

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
        immutable ubyte paddingByte = ((this.value[0] & 0x80u) ? 0xFFu : 0x00u);
        while (value.length < T.sizeof)
            value = (paddingByte ~ value);
        version (LittleEndian) reverse(value);
        version (unittest) assert(value.length == T.sizeof);
        return *cast(T *) value.ptr;
    }

    /**
        Encodes an ENUMERATED type from an integer. In BER, an ENUMERATED
        type is encoded the exact same way that an INTEGER is.
    */
    public @property @system nothrow
    void enumerated(T)(in T value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        if (value <= byte.max && value >= byte.min)
        {
            this.value = [ cast(ubyte) cast(byte) value ];
            return;
        }

        ubyte[] ub;
        ub.length = T.sizeof;
        *cast(T *)&ub[0] = value;
        version (LittleEndian) reverse(ub);

        /*
            An ENUMERATED must be encoded on the fewest number of bytes than can
            encode it. The loops below identify how many bytes can be
            truncated from the start of the ENUMERATED, with one loop for positive
            and another loop for negative numbers. ENUMERATED is encoded in the
            same exact way that INTEGER is encoded.

            From X.690, Section 8.3.2:

            If the contents octets of an integer value encoding consist of more
            than one octet, then the bits of the first octet and bit 8 of the
            second octet:
                a) shall not all be ones; and
                b) shall not all be zero.
                NOTE – These rules ensure that an integer value is always
                encoded in the smallest possible number of octets.
        */
        size_t startOfNonPadding = 0u;
        if (T.sizeof > 1u)
        {
            if (value >= 0)
            {
                for (size_t i = 0u; i < ub.length-1; i++)
                {
                    if (ub[i] != 0x00u) break;
                    if (!(ub[i+1] & 0x80u)) startOfNonPadding++;
                }
            }
            else
            {
                for (size_t i = 0u; i < ub.length-1; i++)
                {
                    if (ub[i] != 0xFFu) break;
                    if (ub[i+1] & 0x80u) startOfNonPadding++;
                }
            }
        }

        this.value = ub[startOfNonPadding .. $];
    }

    // Ensure that ENUMERATED 0 gets encoded on a single null byte.
    @system
    unittest
    {
        BERElement el = new BERElement();

        el.enumerated!byte = cast(byte) 0x00;
        assert(el.value == [ 0x00u ]);

        el.enumerated!short = cast(short) 0x0000;
        assert(el.value == [ 0x00u ]);

        el.enumerated!int = cast(int) 0;
        assert(el.value == [ 0x00u ]);

        el.enumerated!long = cast(long) 0;
        assert(el.value == [ 0x00u ]);

        el.value = [];
        assertThrown!ASN1ValueInvalidException(el.enumerated!byte);
        assertThrown!ASN1ValueInvalidException(el.enumerated!short);
        assertThrown!ASN1ValueInvalidException(el.enumerated!int);
        assertThrown!ASN1ValueInvalidException(el.enumerated!long);
    }

    // Test encoding -0 for the sake of CVE-2016-2108
    @system
    unittest
    {
        BERElement el = new BERElement();

        el.enumerated!byte = -0;
        assertNotThrown!RangeError(el.enumerated!byte);
        assertNotThrown!ASN1Exception(el.enumerated!byte);

        el.enumerated!short = -0;
        assertNotThrown!RangeError(el.enumerated!short);
        assertNotThrown!ASN1Exception(el.enumerated!short);

        el.enumerated!int = -0;
        assertNotThrown!RangeError(el.enumerated!int);
        assertNotThrown!ASN1Exception(el.enumerated!int);

        el.enumerated!long = -0;
        assertNotThrown!RangeError(el.enumerated!long);
        assertNotThrown!ASN1Exception(el.enumerated!long);
    }

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
        const BERElement[] components = this.sequence;
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length != 2u)
            throw new ASN1ValueSizeException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EMBEDDED PDV that contained too many or too few elements. " ~
                "An EMBEDDED PDV should have only two elements: " ~
                "an identification CHOICE, and a data-value OCTET STRING, " ~
                "in that order. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        if
        (
            components[0].tagClass != ASN1TagClass.contextSpecific ||
            components[1].tagClass != ASN1TagClass.contextSpecific
        )
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode an " ~
                "EMBEDDED PDV that contained a tag that was not of CONTEXT-" ~
                "SPECIFIC class. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        /* NOTE:
            See page 224 of Dubuisson, item 11:
            It sounds like, even if you have an ABSENT constraint applied,
            all automatically-tagged items still have the same numbers as
            though the constrained component were PRESENT.
        */
        if (components[0].tagNumber != 0u || components[1].tagNumber != 2u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode an " ~
                "EMBEDDED PDV that contained a component whose tag number " ~
                "was neither 0 nor 2, which indicate the identification CHOICE " ~
                "and the string-value OCTET STRING components respectively. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        ubyte[] bytes = components[0].value.dup;
        const BERElement identificationChoice = new BERElement(bytes);
        switch (identificationChoice.tagNumber)
        {
            case (0u): // syntaxes
            {
                const BERElement[] syntaxesComponents = identificationChoice.sequence;

                if (syntaxesComponents.length != 2u)
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EMBEDDED PDV whose syntaxes component " ~
                        "contained an invalid number of elements. The " ~
                        "syntaxes component should contain abstract and transfer " ~
                        "syntax OBJECT IDENTIFIERS, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                if
                (
                    syntaxesComponents[0].tagClass != ASN1TagClass.contextSpecific ||
                    syntaxesComponents[1].tagClass != ASN1TagClass.contextSpecific
                )
                    throw new ASN1TagException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EMBEDDED PDV whose syntaxes contained a " ~
                        "component whose tag class was not CONTEXT-SPECIFIC. " ~
                        "All elements of the syntaxes component MUST be of " ~
                        "CONTEXT-SPECIFIC class. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                if
                (
                    syntaxesComponents[0].tagNumber != 0u ||
                    syntaxesComponents[1].tagNumber != 1u
                )
                    throw new ASN1TagException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EMBEDDED PDV whose syntaxes component " ~
                        "contained a component whose tag number was not correct. " ~
                        "The tag numbers of the syntaxes component " ~
                        "must be 0 and 1, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                identification.syntaxes  = ASN1Syntaxes(
                    syntaxesComponents[0].objectIdentifier,
                    syntaxesComponents[1].objectIdentifier
                );

                break;
            }
            case (1u): // syntax
            {
                identification.syntax = identificationChoice.objectIdentifier;
                break;
            }
            case (2u): // presentation-context-id
            {
                identification.presentationContextID = identificationChoice.integer!ptrdiff_t;
                break;
            }
            case (3u): // context-negotiation
            {
                const BERElement[] contextNegotiationComponents = identificationChoice.sequence;

                if (contextNegotiationComponents.length != 2u)
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EMBEDDED PDV whose context-negotiation " ~
                        "contained an invalid number of elements. The " ~
                        "context-negotiation component should contain a " ~
                        "presentation-context-id INTEGER and transfer-syntax " ~
                        "OBJECT IDENTIFIER in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                if
                (
                    contextNegotiationComponents[0].tagClass != ASN1TagClass.contextSpecific ||
                    contextNegotiationComponents[1].tagClass != ASN1TagClass.contextSpecific
                )
                    throw new ASN1TagException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EMBEDDED PDV whose context-negotiation " ~
                        "contained a component whose tag class was not CONTEXT-" ~
                        "SPECIFIC. All elements of the context-negotiation " ~
                        "component MUST be of CONTEXT-SPECIFIC class." ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                if
                (
                    contextNegotiationComponents[0].tagNumber != 0u ||
                    contextNegotiationComponents[1].tagNumber != 1u
                )
                    throw new ASN1TagException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EMBEDDED PDV whose context-negotiation " ~
                        "contained a component whose tag number was not correct. " ~
                        "The tag numbers of the context-negotiation component " ~
                        "must be 0 and 1, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                identification.contextNegotiation  = ASN1ContextNegotiation(
                    contextNegotiationComponents[0].integer!ptrdiff_t,
                    contextNegotiationComponents[1].objectIdentifier
                );

                break;
            }
            case (4u): // transfer-syntax
            {
                identification.transferSyntax = identificationChoice.objectIdentifier;
                break;
            }
            case (5u): // fixed
            {
                identification.fixed = true;
                break;
            }
            default:
            {
                throw new ASN1TagException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an EMBEDDED PDV whose identification CHOICE has a tag " ~
                    "not recognized by the specification of the EMBEDDED PDV. " ~
                    "The EMBEDDED PDV accepts identification CHOICEs with tag " ~
                    "numbers from 0 to 5. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
            }
        }

        EmbeddedPDV pdv = EmbeddedPDV();
        pdv.identification = identification;
        pdv.dataValue = components[1].octetString;
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
            ASN1ValueInvalidException = if encoded ObjectDescriptor contains
                invalid characters.
    */
    override public @property @system
    void embeddedPresentationDataValue(in EmbeddedPDV value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        BERElement identification = new BERElement();
        identification.tagClass = ASN1TagClass.contextSpecific;
        identification.tagNumber = 0u; // CHOICE is EXPLICIT, even with automatic tagging.

        BERElement identificationChoice = new BERElement();
        identificationChoice.tagClass = ASN1TagClass.contextSpecific;
        if (!(value.identification.syntaxes.isNull))
        {
            BERElement abstractSyntax = new BERElement();
            abstractSyntax.tagClass = ASN1TagClass.contextSpecific;
            abstractSyntax.tagNumber = 0u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            BERElement transferSyntax = new BERElement();
            transferSyntax.tagClass = ASN1TagClass.contextSpecific;
            transferSyntax.tagNumber = 1u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationChoice.tagNumber = 0u;
            identificationChoice.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationChoice.tagNumber = 1u;
            identificationChoice.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.contextNegotiation.isNull))
        {
            BERElement presentationContextID = new BERElement();
            presentationContextID.tagClass = ASN1TagClass.contextSpecific;
            presentationContextID.tagNumber = 0u;
            presentationContextID.integer!ptrdiff_t = value.identification.contextNegotiation.presentationContextID;

            BERElement transferSyntax = new BERElement();
            transferSyntax.tagClass = ASN1TagClass.contextSpecific;
            transferSyntax.tagNumber = 1u;
            transferSyntax.objectIdentifier = value.identification.contextNegotiation.transferSyntax;

            identificationChoice.tagNumber = 3u;
            identificationChoice.sequence = [ presentationContextID, transferSyntax ];
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationChoice.tagNumber = 4u;
            identificationChoice.objectIdentifier = value.identification.transferSyntax;
        }
        else if (value.identification.fixed)
        {
            identificationChoice.tagNumber = 5u;
            identificationChoice.value = [];
        }
        else // it must be the presentationContextID INTEGER
        {
            identificationChoice.tagNumber = 2u;
            identificationChoice.integer!ptrdiff_t = value.identification.presentationContextID;
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationChoice;

        BERElement dataValue = new BERElement();
        dataValue.tagClass = ASN1TagClass.contextSpecific;
        dataValue.tagNumber = 2u;
        dataValue.octetString = value.dataValue;

        this.sequence = [ identification, dataValue ];
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because DER and CER
        do not support encoding of presentation-context-id in EMBEDDED PDV.
    */
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        EmbeddedPDV input = EmbeddedPDV();
        input.identification = id;
        input.dataValue = [ 0x01u, 0x02u, 0x03u, 0x04u ];

        BERElement el = new BERElement();
        el.tagNumber = 0x08u;
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.presentationContextID == 27L);
        assert(output.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]);
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because DER and CER
        do not support encoding of context-negotiation in EMBEDDED PDV.
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

        BERElement el = new BERElement();
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.contextNegotiation.presentationContextID == 27L);
        assert(output.identification.contextNegotiation.transferSyntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.dataValue == [ 0x13u, 0x15u, 0x17u, 0x19u ]);
    }

    // Inspired by CVE-2017-9023
    @system
    unittest
    {
        ubyte[] data = [ // This is valid.
            0x0Bu, 0x0Au, // EMBEDDED PDV, Length 11
                0x80u, 0x02u, // CHOICE
                    0x85u, 0x00u, // NULL
                0x82u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u ]; // OCTET STRING

        // Valid values for data[2]: 80
        for (ubyte i = 0x81u; i < 0x9Eu; i++)
        {
            data[2] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, data);
            assertThrown!ASN1Exception(el.embeddedPDV);
        }

        // Valid values for data[4]: 80-85
        for (ubyte i = 0x86u; i < 0x9Eu; i++)
        {
            data[4] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, data);
            assertThrown!ASN1Exception(el.embeddedPDV);
        }

        // Valid values for data[6]: 82
        for (ubyte i = 0x83u; i < 0x9Eu; i++)
        {
            data[6] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, data);
            assertThrown!ASN1Exception(el.embeddedPDV);
        }
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
    void unicodeTransformationFormat8String(in string value)
    {
        this.value = cast(ubyte[]) value.dup;
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
    override public @property @system
    OIDNode[] relativeObjectIdentifier() const
    {
        if (this.value.length == 0u) return [];
        foreach (immutable octet; this.value)
        {
            if (octet == 0x80u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a RELATIVE OID that contained a number that was " ~
                    "encoded on more than the minimum necessary octets. This " ~
                    "is indicated by an occurrence of the octet 0x80, which " ~
                    "is the encoded equivalent of a leading zero. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
        }

        if (this.value[$-1] > 0x80u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode " ~
                "a RELATIVE OID whose last byte had the most significant " ~
                "bit set, which is used to indicate the continuity of the " ~
                "encoding of a number on the next octet. In other words, the " ~
                "encoded data appears to be truncated. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        // Breaks bytes into groups, where each group encodes one OID component.
        ubyte[][] byteGroups;
        size_t lastTerminator = 0u;
        for (size_t i = 0u; i < this.length; i++)
        {
            if (!(this.value[i] & 0x80u))
            {
                byteGroups ~= cast(ubyte[]) this.value[lastTerminator .. i+1];
                lastTerminator = i+1;
            }
        }

        // Converts each group of bytes to a number.
        size_t[] numbers;
        foreach (const byteGroup; byteGroups)
        {
            if (byteGroup.length > size_t.sizeof)
                throw new ASN1ValueTooBigException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a RELATIVE OID that encoded a number on more than " ~
                    "size_t bytes. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );

            numbers ~= 0u;
            for (size_t i = 0u; i < byteGroup.length; i++)
            {
                numbers[$-1] <<= 7;
                numbers[$-1] |= cast(size_t) (byteGroup[i] & 0x7Fu);
            }
        }

        // Constructs the array of OIDNodes from the array of numbers.
        OIDNode[] nodes;
        foreach (number; numbers)
        {
            nodes ~= OIDNode(number);
        }

        return nodes;
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
    void relativeObjectIdentifier(in OIDNode[] value)
    {
        foreach (node; value)
        {
            size_t number = node.number;
            if (number < 128u)
            {
                this.value ~= cast(ubyte) number;
                continue;
            }

            ubyte[] encodedOIDNode;
            while (number != 0u)
            {
                ubyte[] numberBytes;
                numberBytes.length = size_t.sizeof;
                *cast(size_t *) numberBytes.ptr = number;
                if ((numberBytes[0] & 0x80u) == 0u) numberBytes[0] |= 0x80u;
                encodedOIDNode = numberBytes[0] ~ encodedOIDNode;
                number >>= 7u;
            }

            encodedOIDNode[$-1] &= 0x7Fu;
            this.value ~= encodedOIDNode;
        }
    }

    @system
    unittest
    {
        BERElement element = new BERElement();

        // All values of octet[0] should pass.
        for (ubyte i = 0x00u; i < 0x80u; i++)
        {
            element.value = [ i ];
            assertNotThrown!Exception(element.roid);
        }

        // All values of octet[0] should pass.
        for (ubyte i = 0x81u; i < 0xFFu; i++)
        {
            element.value = [ i, 0x14u ];
            assertNotThrown!Exception(element.roid);
        }
    }

    @system
    unittest
    {
        BERElement element = new BERElement();

        // Tests for the "leading zero byte," 0x80
        element.value = [ 0x29u, 0x80u ];
        assertThrown!ASN1ValueInvalidException(element.roid);
        element.value = [ 0x29u, 0x80u, 0x14u ];
        assertThrown!ASN1ValueInvalidException(element.roid);
        element.value = [ 0x29u, 0x14u, 0x80u ];
        assertThrown!ASN1ValueInvalidException(element.roid);
        element.value = [ 0x29u, 0x80u, 0x80u ];
        assertThrown!ASN1ValueInvalidException(element.roid);
        element.value = [ 0x80u, 0x80u, 0x80u ];
        assertThrown!ASN1ValueInvalidException(element.roid);

        // Test for non-terminating components
        element.value = [ 0x29u, 0x81u ];
        assertThrown!ASN1ValueInvalidException(element.roid);
        element.value = [ 0x29u, 0x14u, 0x81u ];
        assertThrown!ASN1ValueInvalidException(element.roid);
    }

    /**
        Decodes a sequence of BERElements.

        Returns: an array of BERElements.
        Throws:
            ASN1ValueSizeException = if long definite-length is too big to be
                decoded to an unsigned integral type.
            ASN1ValueTooSmallException = if there are fewer value bytes than
                indicated by the length tag.
    */
    override public @property @system
    BERElement[] sequence() const
    {
        ubyte[] data = this.value.dup;
        BERElement[] result;
        while (data.length > 0u)
            result ~= new BERElement(data);
        return result;
    }

    /**
        Encodes a sequence of BERElements.
    */
    override public @property @system
    void sequence(in BERElement[] value)
    {
        ubyte[] result;
        foreach (bv; value)
        {
            result ~= bv.toBytes;
        }
        this.value = result;
    }

    /**
        Decodes a set of BERElements.

        Returns: an array of BERElements.
        Throws:
            ASN1ValueSizeException = if long definite-length is too big to be
                decoded to an unsigned integral type.
            ASN1ValueTooSmallException = if there are fewer value bytes than
                indicated by the length tag.
    */
    override public @property @system
    BERElement[] set() const
    {
        ubyte[] data = this.value.dup;
        BERElement[] result;
        while (data.length > 0u)
            result ~= new BERElement(data);
        return result;
    }

    /**
        Encodes a set of BERElements.
    */
    override public @property @system
    void set(in BERElement[] value)
    {
        ubyte[] result;
        foreach (bv; value)
        {
            result ~= bv.toBytes;
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
        foreach (immutable character; this.value)
        {
            if (!canFind(numericStringCharacters, character))
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a NumericString that contained a character that " ~
                    "is not numeric or space. The encoding of the offending character is '" ~
                    text(cast(uint) character) ~ "'. " ~ notWhatYouMeantText ~
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
    void numericString(in string value)
    {
        foreach (immutable character; value)
        {
            if (!canFind(numericStringCharacters, character))
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a NumericString that contained a character that " ~
                    "is not numeric or space. The encoding of the offending character is '" ~
                    text(cast(uint) character) ~ "'. " ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
        }
        this.value = cast(ubyte[]) value.dup;
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
        foreach (immutable character; this.value)
        {
            if (!canFind(printableStringCharacters, character))
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a PrintableString that contained a character that " ~
                    "is not considered 'printable' by the specification. " ~
                    "The encoding of the offending character is '" ~
                    text(cast(uint) character) ~ "'. " ~
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
    void printableString(in string value)
    {
        foreach (immutable character; value)
        {
            if (!canFind(printableStringCharacters, character))
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to encode " ~
                    "a PrintableString that contained a character that " ~
                    "is not considered 'printable' by the specification. " ~
                    "The encoding of the offending character is '" ~
                    text(cast(uint) character) ~ "'. " ~
                    "The allowed characters are: " ~ printableStringCharacters ~ " " ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        this.value = cast(ubyte[]) value.dup;
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
    void teletexString(in ubyte[] value)
    {
        // TODO: Validation.
        this.value = value.dup;
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
    void videotexString(in ubyte[] value)
    {
        // TODO: Validation.
        this.value = value.dup;
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
        foreach (immutable character; ret)
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
    void internationalAlphabetNumber5String(in string value)
    {
        foreach (immutable character; value)
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
        this.value = cast(ubyte[]) value.dup;
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

        Throws:
            DateTimeException = if string cannot be decoded to a DateTime
    */
    override public @property @system
    DateTime coordinatedUniversalTime() const
    {
        if (this.value.length < 10u)
            throw new ASN1ValueTooSmallException
            (
                "This exception was thrown because you attempted to decode a " ~
                "UTCTime that was encoded on too few bytes to be " ~
                "correct. A GeneralizedTime needs at least 12 bytes. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        /** NOTE:
            .fromISOString() MUST be called from SysTime, not DateTime. There
            is a subtle difference in how .fromISOString() works in both SysTime
            and DateTime: SysTime's accepts the "Z" at the end (indicating that
            the time is in GMT).

            If you use DateTime.fromISOString, you will get a DateTimeException
            whose cryptic message reads "Invalid ISO String: " followed,
            strangely, by only the last six characters of the string.
        */
        immutable string dt = (((this.value[0] <= '7') ? "20" : "19") ~ cast(string) this.value);
        return cast(DateTime) SysTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
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
    override public @property @system nothrow
    void coordinatedUniversalTime(in DateTime value)
    out
    {
        assert(this.value.length > 10u);
    }
    body
    {
        import std.string : replace;
        immutable SysTime st = SysTime(value, UTC());
        this.value = cast(ubyte[]) ((st.toUTC()).toISOString()[2 .. $].replace("T", ""));
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

        Throws:
            DateTimeException = if string cannot be decoded to a DateTime
    */
    override public @property @system
    DateTime generalizedTime() const
    {
        if (this.value.length < 10u)
            throw new ASN1ValueTooSmallException
            (
                "This exception was thrown because you attempted to decode a " ~
                "GeneralizedTime that was encoded on too few bytes to be " ~
                "correct. A GeneralizedTime needs at least 14 bytes. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        /** NOTE:
            .fromISOString() MUST be called from SysTime, not DateTime. There
            is a subtle difference in how .fromISOString() works in both SysTime
            and DateTime: SysTime's accepts the "Z" at the end (indicating that
            the time is in GMT).

            If you use DateTime.fromISOString, you will get a DateTimeException
            whose cryptic message reads "Invalid ISO String: " followed,
            strangely, by only the last six characters of the string.
        */
        immutable string dt = cast(string) this.value;
        return cast(DateTime) SysTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
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
    override public @property @system nothrow
    void generalizedTime(in DateTime value)
    out
    {
        assert(this.value.length > 10u);
    }
    body
    {
        import std.string : replace;
        immutable SysTime st = SysTime(value, UTC());
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
        foreach (immutable character; ret)
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
    void graphicString(in string value)
    {
        foreach (immutable character; value)
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
        this.value = cast(ubyte[]) value.dup;
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
        foreach (immutable character; ret)
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
    void visibleString(in string value)
    {
        foreach (immutable character; value)
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
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a string containing only ASCII characters.

        Deprecated, according to page 182 of the Dubuisson book.

        Returns: a string.
        Throws:
            ASN1ValueInvalidException = if any enecoded character is not ASCII.

        Citations:
            Dubuisson, Olivier. “Basic Encoding Rules (BER).” ASN.1:
            Communication between Heterogeneous Systems, Morgan Kaufmann,
            2001, p. 182.
    */
    override public @property @system
    string generalString() const
    {
        string ret = cast(string) this.value;
        foreach (immutable character; ret)
        {
            if (!character.isASCII)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "an GeneralString that contained a character that " ~
                    "is not ASCII. The encoding of the offending character is '" ~
                    text(cast(uint) character) ~ "'. " ~
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
            Dubuisson, Olivier. “Basic Encoding Rules (BER).” ASN.1:
            Communication between Heterogeneous Systems, Morgan Kaufmann,
            2001, p. 182.
    */
    override public @property @system
    void generalString(in string value)
    {
        foreach (immutable character; value)
        {
            if (!character.isASCII)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you tried to decode " ~
                    "an GeneralString that contained a character that " ~
                    "is not ASCII. The encoding of the offending character is '" ~
                    text(cast(uint) character) ~ "'. " ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        this.value = cast(ubyte[]) value.dup;
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
            size_t i = 0u;
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
    void universalString(in dstring value)
    {
        version (BigEndian)
        {
            this.value = cast(ubyte[]) value.dup;
        }
        else version (LittleEndian)
        {
            foreach(immutable character; value)
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
        const BERElement[] components = this.sequence;
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length != 2u)
            throw new ASN1ValueSizeException
            (
                "This exception was thrown because you attempted to decode " ~
                "a CharacterString that contained too many or too few elements. " ~
                "A CharacterString should have only two elements: " ~
                "an identification CHOICE, and a data-value OCTET STRING, " ~
                "in that order. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        if
        (
            components[0].tagClass != ASN1TagClass.contextSpecific ||
            components[1].tagClass != ASN1TagClass.contextSpecific
        )
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode a " ~
                "CharacterString that contained a tag that was not of CONTEXT-" ~
                "SPECIFIC class. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        /* NOTE:
            See page 224 of Dubuisson, item 11:
            It sounds like, even if you have an ABSENT constraint applied,
            all automatically-tagged items still have the same numbers as
            though the constrained component were PRESENT.
        */
        if (components[0].tagNumber != 0u || components[1].tagNumber != 2u)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode a " ~
                "CharacterString that contained a component whose tag number " ~
                "was neither 0 nor 2, which indicate the identification CHOICE " ~
                "and the string-value OCTET STRING components respectively. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        ubyte[] bytes = components[0].value.dup;
        const BERElement identificationChoice = new BERElement(bytes);
        switch (identificationChoice.tagNumber)
        {
            case (0u): // syntaxes
            {
                const BERElement[] syntaxesComponents = identificationChoice.sequence;

                if (syntaxesComponents.length != 2u)
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a CharacterString whose syntaxes component " ~
                        "contained an invalid number of elements. The " ~
                        "syntaxes component should contain abstract and transfer " ~
                        "syntax OBJECT IDENTIFIERS, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                if
                (
                    syntaxesComponents[0].tagClass != ASN1TagClass.contextSpecific ||
                    syntaxesComponents[1].tagClass != ASN1TagClass.contextSpecific
                )
                    throw new ASN1TagException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a CharacterString whose syntaxes contained a " ~
                        "component whose tag class was not CONTEXT-SPECIFIC. " ~
                        "All elements of the syntaxes component MUST be of " ~
                        "CONTEXT-SPECIFIC class. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                if
                (
                    syntaxesComponents[0].tagNumber != 0u ||
                    syntaxesComponents[1].tagNumber != 1u
                )
                    throw new ASN1TagException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a CharacterString whose syntaxes component " ~
                        "contained a component whose tag number was not correct. " ~
                        "The tag numbers of the syntaxes component " ~
                        "must be 0 and 1, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                identification.syntaxes = ASN1Syntaxes(
                    syntaxesComponents[0].objectIdentifier,
                    syntaxesComponents[1].objectIdentifier
                );

                break;
            }
            case (1u): // syntax
            {
                identification.syntax = identificationChoice.objectIdentifier;
                break;
            }
            case (2u): // presentation-context-id
            {
                identification.presentationContextID = identificationChoice.integer!ptrdiff_t;
                break;
            }
            case (3u): // context-negotiation
            {
                const BERElement[] contextNegotiationComponents = identificationChoice.sequence;

                if (contextNegotiationComponents.length != 2u)
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a CharacterString whose context-negotiation " ~
                        "contained an invalid number of elements. The " ~
                        "context-negotiation component should contain a " ~
                        "presentation-context-id INTEGER and transfer-syntax " ~
                        "OBJECT IDENTIFIER in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                if
                (
                    contextNegotiationComponents[0].tagClass != ASN1TagClass.contextSpecific ||
                    contextNegotiationComponents[1].tagClass != ASN1TagClass.contextSpecific
                )
                    throw new ASN1TagException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a CharacterString whose context-negotiation " ~
                        "contained a component whose tag class was not CONTEXT-" ~
                        "SPECIFIC. All elements of the context-negotiation " ~
                        "component MUST be of CONTEXT-SPECIFIC class." ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                if
                (
                    contextNegotiationComponents[0].tagNumber != 0u ||
                    contextNegotiationComponents[1].tagNumber != 1u
                )
                    throw new ASN1TagException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a CharacterString whose context-negotiation " ~
                        "contained a component whose tag number was not correct. " ~
                        "The tag numbers of the context-negotiation component " ~
                        "must be 0 and 1, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                identification.contextNegotiation = ASN1ContextNegotiation(
                    contextNegotiationComponents[0].integer!ptrdiff_t,
                    contextNegotiationComponents[1].objectIdentifier
                );

                break;
            }
            case (4u): // transfer-syntax
            {
                identification.transferSyntax = identificationChoice.objectIdentifier;
                break;
            }
            case (5u): // fixed
            {
                identification.fixed = true;
                break;
            }
            default:
            {
                throw new ASN1TagException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a CharacterString whose identification CHOICE has a tag " ~
                    "not recognized by the specification of the CharacterString. " ~
                    "The CharacterString accepts identification CHOICEs with tag " ~
                    "numbers from 0 to 5. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
            }
        }

        CharacterString cs = CharacterString();
        cs.identification = identification;
        cs.stringValue = components[1].octetString;
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
    void characterString(in CharacterString value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        BERElement identification = new BERElement();
        identification.tagClass = ASN1TagClass.contextSpecific;
        identification.tagNumber = 0u; // CHOICE is EXPLICIT, even with automatic tagging.

        BERElement identificationChoice = new BERElement();
        identificationChoice.tagClass = ASN1TagClass.contextSpecific;
        if (!(value.identification.syntaxes.isNull))
        {
            BERElement abstractSyntax = new BERElement();
            abstractSyntax.tagClass = ASN1TagClass.contextSpecific;
            abstractSyntax.tagNumber = 0u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            BERElement transferSyntax = new BERElement();
            transferSyntax.tagClass = ASN1TagClass.contextSpecific;
            transferSyntax.tagNumber = 1u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationChoice.tagNumber = 0u;
            identificationChoice.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationChoice.tagNumber = 1u;
            identificationChoice.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.contextNegotiation.isNull))
        {
            BERElement presentationContextID = new BERElement();
            presentationContextID.tagClass = ASN1TagClass.contextSpecific;
            presentationContextID.tagNumber = 0u;
            presentationContextID.integer!ptrdiff_t = value.identification.contextNegotiation.presentationContextID;

            BERElement transferSyntax = new BERElement();
            transferSyntax.tagClass = ASN1TagClass.contextSpecific;
            transferSyntax.tagNumber = 1u;
            transferSyntax.objectIdentifier = value.identification.contextNegotiation.transferSyntax;

            identificationChoice.tagNumber = 3u;
            identificationChoice.sequence = [ presentationContextID, transferSyntax ];
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationChoice.tagNumber = 4u;
            identificationChoice.objectIdentifier = value.identification.transferSyntax;
        }
        else if (value.identification.fixed)
        {
            identificationChoice.tagNumber = 5u;
            identificationChoice.value = [];
        }
        else // it must be the presentationContextID INTEGER
        {
            identificationChoice.tagNumber = 2u;
            identificationChoice.integer!ptrdiff_t = value.identification.presentationContextID;
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationChoice;

        BERElement stringValue = new BERElement();
        stringValue.tagClass = ASN1TagClass.contextSpecific;
        stringValue.tagNumber = 2u;
        stringValue.octetString = value.stringValue;

        this.sequence = [ identification, stringValue ];
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element, because Distinguished
        Encoding Rules (DER) does not permit CharacterStrings to use an identification
        CHOICE of presentation-context-id or context-negotiation
    */
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        CharacterString input = CharacterString();
        input.identification = id;
        input.stringValue = [ 'H', 'E', 'N', 'L', 'O' ];

        BERElement el = new BERElement();
        el.tagNumber = 0x08u;
        el.characterString = input;
        CharacterString output = el.characterString;
        assert(output.identification.presentationContextID == 27L);
        assert(output.stringValue == [ 'H', 'E', 'N', 'L', 'O' ]);
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element, because Distinguished
        Encoding Rules (DER) does not permit CharacterStrings to use an identification
        CHOICE of presentation-context-id or context-negotiation
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

        BERElement el = new BERElement();
        el.characterString = input;
        CharacterString output = el.characterString;
        assert(output.identification.contextNegotiation.presentationContextID == 27L);
        assert(output.identification.contextNegotiation.transferSyntax == new OID(1, 3, 6, 4, 1, 256, 39));
        assert(output.stringValue == [ 'H', 'E', 'N', 'L', 'O' ]);
    }

    // Inspired by CVE-2017-9023
    @system
    unittest
    {
        ubyte[] data = [ // This is valid.
            0x1Eu, 0x0Au, // CharacterString, Length 11
                0x80u, 0x02u, // CHOICE
                    0x85u, 0x00u, // NULL
                0x82u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u ]; // OCTET STRING

        // Valid values for data[2]: 80
        for (ubyte i = 0x81u; i < 0x9Eu; i++)
        {
            data[2] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, data);
            assertThrown!ASN1Exception(el.characterString);
        }

        // Valid values for data[4]: 80-85
        for (ubyte i = 0x86u; i < 0x9Eu; i++)
        {
            data[4] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, data);
            assertThrown!ASN1Exception(el.characterString);
        }

        // Valid values for data[6]: 82
        for (ubyte i = 0x83u; i < 0x9Eu; i++)
        {
            data[6] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, data);
            assertThrown!ASN1Exception(el.characterString);
        }
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
            size_t i = 0u;
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
    void basicMultilingualPlaneString(in wstring value)
    {
        version (BigEndian)
        {
            this.value = cast(ubyte[]) value.dup;
        }
        else version (LittleEndian)
        {
            foreach(immutable character; value)
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
        Creates an EndOfContent BER Value.
    */
    public @safe @nogc nothrow
    this()
    {
        this.tagNumber = 0u;
        this.value = [];
    }

    /**
        Creates a BERElement from the supplied bytes, inferring that the first
        byte is the type tag. The supplied ubyte[] array is "chomped" by
        reference, so the original array will grow shorter as BERElements are
        generated.

        Throws:
            ASN1ValueTooSmallException = if the bytes supplied are fewer than
                two (one or zero, in other words), such that no valid BERElement
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
        BERElement[] result;
        while (bytes.length > 0)
            result ~= new BERElement(bytes);

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
        immutable size_t bytesRead = this.fromBytes(bytes);
        bytes = bytes[bytesRead .. $];
    }

    /**
        Creates a BERElement from the supplied bytes, inferring that the first
        byte is the type tag. The supplied ubyte[] array is read, starting
        from the index specified by $(D bytesRead), and increments
        $(D bytesRead) by the number of bytes read.

        Throws:
            ASN1ValueTooSmallException = if the bytes supplied are fewer than
                two (one or zero, in other words), such that no valid BERElement
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
        BERElement[] result;
        size_t i = 0u;
        while (i < bytes.length)
            result ~= new BERElement(i, bytes);

        // Encoding looks like:
        ubyte[] result;
        foreach (bv; bervalues)
        {
            result ~= cast(ubyte[]) bv;
        }
        ---
    */
    public @system
    this(ref size_t bytesRead, in ubyte[] bytes)
    {
        bytesRead += this.fromBytes(bytes[bytesRead .. $].dup);
    }

    // Returns the number of bytes read
    public
    size_t fromBytes (in ubyte[] bytes)
    {
        if (bytes.length < 2u)
            throw new ASN1ValueTooSmallException
            (
                "This exception was thrown because you attempted to decode " ~
                "a Basic Encoding Rules (BER) encoded element from fewer than " ~
                "two bytes, which cannot possibly encode a valid Basic " ~
                "Encoding Rules (BER) element. "
            );

        // Index of what we are currently parsing.
        size_t cursor = 0u;

        switch (bytes[cursor] & 0b1100_0000u)
        {
            case (0b0000_0000u):
            {
                this.tagClass = ASN1TagClass.universal;
                break;
            }
            case (0b0100_0000u):
            {
                this.tagClass = ASN1TagClass.application;
                break;
            }
            case (0b1000_0000u):
            {
                this.tagClass = ASN1TagClass.contextSpecific;
                break;
            }
            case (0b1100_0000u):
            {
                this.tagClass = ASN1TagClass.privatelyDefined;
                break;
            }
            default:
            {
                assert(0, "Impossible tag class appeared!");
            }
        }

        switch (bytes[cursor] & 0b0010_0000u)
        {
            case (0b0000_0000u):
            {
                this.construction = ASN1Construction.primitive;
                break;
            }
            case (0b0010_0000u):
            {
                this.construction = ASN1Construction.constructed;
                break;
            }
            default:
            {
                assert(0, "Impossible tag class appeared!");
            }
        }

        this.tagNumber = (bytes[cursor] & 0b00011111u);
        cursor++;
        if (this.tagNumber >= 31u)
        {
            /* NOTE:
                Section 8.1.2.4.2, point C of the International
                Telecommunications Union's X.690 specification says:

                "bits 7 to 1 of the first subsequent octet shall not all be zero."

                in reference to the bytes used to encode the tag number in long
                form, which happens when the least significant five bits of the
                first byte are all set.

                This essentially means that the long-form tag number must be
                encoded on the fewest possible octets. If the first byte is
                0x80, then it is not encoded on the fewest possible octets.
            */
            if (bytes[cursor] == 0b1000_0000u)
                throw new ASN1TagException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a Basic Encoding Rules (BER) encoded element whose tag " ~
                    "number was encoded in long form in the octets following " ~
                    "the first octet of the type tag, and whose tag number " ~
                    "was encoded with a 'leading zero' byte, 0x80. When " ~
                    "using Basic Encoding Rules (BER), the tag number must " ~
                    "be encoded on the smallest number of octets possible, " ~
                    "which the inclusion of leading zero bytes necessarily " ~
                    "contradicts. " ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );

            this.tagNumber = 0u;

            // This loop looks for the end of the encoded tag number.
            immutable size_t limit = ((bytes.length-1 >= size_t.sizeof) ? size_t.sizeof : bytes.length-1);
            while (cursor < limit)
            {
                if (!(bytes[cursor++] & 0x80u)) break;
            }

            if (bytes[cursor-1] & 0x80u)
                throw new ASN1TagException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a Basic Encoding Rules (BER) encoded element that encoded " ~
                    "a tag number that was either too large to decode or " ~
                    "terminated prematurely."
                );

            for (size_t i = 1; i < cursor; i++)
            {
                this.tagNumber <<= 7;
                this.tagNumber |= cast(size_t) (bytes[i] & 0x7Fu);
            }
        }

        // Length
        if ((bytes[cursor] & 0x80u) == 0x80u)
        {
            immutable ubyte numberOfLengthOctets = (bytes[cursor] & 0x7Fu);
            if (numberOfLengthOctets) // Definite Long or Reserved
            {
                if (numberOfLengthOctets == 0b01111111u) // Reserved
                    throw new ASN1InvalidLengthException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Basic Encoding Rules (BER) encoded element " ~
                        "whose length tag was 0xFF, which is reserved by the " ~
                        "specification."
                    );

                // Definite Long, if it has made it this far

                if (numberOfLengthOctets > size_t.sizeof)
                    throw new ASN1ValueTooBigException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Basic Encoding Rules (BER) encoded element " ~
                        "whose length tag was encoded on more than size_t." ~
                        "sizeof bytes, which is too big to decode."
                    );

                if (cursor + numberOfLengthOctets >= bytes.length)
                    throw new ASN1ValueTooSmallException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Basic Encoding Rules (BER) encoded element " ~
                        "whose length bytes are too many to decode from " ~
                        "the deficient bytes supplied."
                    );

                cursor++;
                ubyte[] lengthNumberOctets;
                lengthNumberOctets.length = size_t.sizeof;
                for (ubyte i = numberOfLengthOctets; i > 0u; i--)
                {
                    lengthNumberOctets[size_t.sizeof-i] = bytes[cursor+numberOfLengthOctets-i];
                }
                version (LittleEndian) reverse(lengthNumberOctets);
                size_t length = *cast(size_t *) lengthNumberOctets.ptr;

                if ((cursor + length) < cursor)
                    throw new ASN1ValueTooBigException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Basic Encoding Rules (BER) encoded element " ~
                        "that indicated that it was exceedingly large--so " ~
                        "large, in fact, that it cannot be stored on this " ~
                        "computer (18 exabytes if you are on a 64-bit system). " ~
                        "This may indicate that the data you attempted to " ~
                        "decode was either corrupted, malformed, or deliberately " ~
                        "crafted to hack you. You would be wise to ensure that " ~
                        "you are running the latest stable version of this " ~
                        "library. "
                    );

                cursor += (numberOfLengthOctets);

                if ((cursor + length) > bytes.length)
                    throw new ASN1ValueTooSmallException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Basic Encoding Rules (BER) encoded element " ~
                        "whose indicated length is too large to decode from " ~
                        "the deficient bytes supplied."
                    );

                this.value = bytes[cursor .. cursor+length].dup;
                return (cursor + length);
            }
            else // Indefinite
            {
                if (++(this.nestingRecursionCount) > this.nestingRecursionLimit)
                {
                    this.nestingRecursionCount = 0u;
                    throw new ASN1RecursionException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Basic Encoding Rules (BER) encoded element " ~
                        "that recursed too deep."
                    );
                }

                immutable size_t startOfValue = ++cursor;
                size_t sentinel = cursor; // Used to track the length of the nested elements.
                while (sentinel < bytes.length)
                {
                    BERElement child = new BERElement(sentinel, bytes);
                    if
                    (
                        child.tagClass == ASN1TagClass.universal &&
                        child.construction == ASN1Construction.primitive &&
                        child.tagNumber == ASN1UniversalType.endOfContent &&
                        child.length == 0u
                    )
                    break;

                    if (child.tagClass != this.tagClass)
                    {
                        this.nestingRecursionCount = 0u;
                        throw new ASN1TagException
                        (
                            "This exception was thrown because you attempted " ~
                            "to decode an indefinite-length element that " ~
                            "contained an element that did not share the same " ~
                            "tag class."
                        );
                    }

                    if (child.tagNumber != this.tagNumber)
                    {
                        this.nestingRecursionCount = 0u;
                        throw new ASN1TagException
                        (
                            "This exception was thrown because you attempted " ~
                            "to decode an indefinite-length element that " ~
                            "contained an element that did not share the same " ~
                            "tag number."
                        );
                    }
                }

                if (sentinel == bytes.length && (bytes[sentinel-1] != 0x00u || bytes[sentinel-2] != 0x00u))
                    throw new ASN1ValueTooSmallException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Basic Encoding Rules (BER) encoded element " ~
                        "that was encoded using indefinite length form, but " ~
                        "did not terminate with an END OF CONTENT word (two " ~
                        "consecutive null bytes)."
                    );

                this.nestingRecursionCount--;
                this.value = bytes[startOfValue .. sentinel-2u].dup;
                return (sentinel);
            }
        }
        else // Definite Short
        {
            ubyte length = (bytes[cursor] & 0x7Fu);

            if ((cursor + length) >= bytes.length)
                throw new ASN1ValueTooSmallException
                (
                    "This exception was thrown because you attempted to " ~
                    "decode a Basic Encoding Rules (BER) encoded element " ~
                    "whose indicated length is too large to decode from " ~
                    "the deficient bytes supplied."
                );

            this.value = bytes[++cursor .. cursor+length].dup;
            return (cursor + length);
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
        ubyte[] tagBytes = [ 0x00u ];
        tagBytes[0] |= cast(ubyte) this.tagClass;
        tagBytes[0] |= cast(ubyte) this.construction;

        if (this.tagNumber < 31u)
        {
            tagBytes[0] |= cast(ubyte) this.tagNumber;
        }
        else
        {
            /*
                Per section 8.1.2.4 of X.690:
                The last five bits of the first byte being set indicate that
                the tag number is encoded in base-128 on the subsequent octets,
                using the first bit of each subsequent octet to indicate if the
                encoding continues on the next octet, just like how the
                individual numbers of OBJECT IDENTIFIER and RELATIVE OBJECT
                IDENTIFIER are encoded.
            */
            tagBytes[0] |= cast(ubyte) 0b00011111u;
            size_t number = this.tagNumber; // We do not want to modify by reference.
            ubyte[] encodedNumber;
            while (number != 0u)
            {
                ubyte[] numberbytes;
                numberbytes.length = size_t.sizeof+1;
                *cast(size_t *) numberbytes.ptr = number;
                if ((numberbytes[0] & 0x80u) == 0u) numberbytes[0] |= 0x80u;
                encodedNumber = numberbytes[0] ~ encodedNumber;
                number >>= 7u;
            }
            tagBytes ~= encodedNumber;
            tagBytes[$-1] &= 0x7Fu; // Set first bit of last byte to zero.
        }

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
                    lengthOctets = [ cast(ubyte) 0x80u + cast(ubyte) size_t.sizeof ];
                    size_t length = cast(size_t) this.value.length;
                    ubyte[] lengthNumberOctets = cast(ubyte[]) *cast(ubyte[size_t.sizeof] *) &length;
                    version (LittleEndian) reverse(lengthNumberOctets);
                    lengthOctets ~= lengthNumberOctets;
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
            tagBytes ~
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
        return this.toBytes();
    }

}

// Tests of all types using definite-short encoding.
@system
unittest
{
    // Test data
    immutable ubyte[] dataEndOfContent = [ 0x00u, 0x00u ];
    immutable ubyte[] dataBoolean = [ 0x01u, 0x01u, 0xFFu ];
    immutable ubyte[] dataInteger = [ 0x02u, 0x01u, 0x1Bu ];
    immutable ubyte[] dataBitString = [ 0x03u, 0x03u, 0x07u, 0xF0u, 0xF0u ];
    immutable ubyte[] dataOctetString = [ 0x04u, 0x04u, 0xFF, 0x00u, 0x88u, 0x14u ];
    immutable ubyte[] dataNull = [ 0x05u, 0x00u ];
    immutable ubyte[] dataOID = [ 0x06u, 0x04u, 0x2Bu, 0x06u, 0x04u, 0x01u ];
    immutable ubyte[] dataOD = [ 0x07u, 0x05u, 'H', 'N', 'E', 'L', 'O' ];
    immutable ubyte[] dataExternal = [
        0x08u, 0x09u, 0x02u, 0x01u, 0x1Bu, 0x81, 0x04u, 0x01u,
        0x02u, 0x03u, 0x04u ];
    immutable ubyte[] dataReal = [ 0x09u, 0x03u, 0x80u, 0xFBu, 0x05u ]; // 0.15625 (From StackOverflow question)
    immutable ubyte[] dataEnum = [ 0x0Au, 0x01u, 0x3Fu ];
    immutable ubyte[] dataEmbeddedPDV = [
        0x0Bu, 0x0Bu, 0x80u, 0x03u, 0x82u, 0x01u, 0x1Bu, 0x82u,
        0x04u, 0x01u, 0x02u, 0x03u, 0x04u ];
    immutable ubyte[] dataUTF8 = [ 0x0Cu, 0x05u, 'H', 'E', 'N', 'L', 'O' ];
    immutable ubyte[] dataROID = [ 0x0Du, 0x03u, 0x06u, 0x04u, 0x01u ];
    // sequence
    // set
    immutable ubyte[] dataNumeric = [ 0x12u, 0x07u, '8', '6', '7', '5', '3', '0', '9' ];
    immutable ubyte[] dataPrintable = [ 0x13u, 0x06u, '8', '6', ' ', 'b', 'f', '8' ];
    immutable ubyte[] dataTeletex = [ 0x14u, 0x06u, 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ];
    immutable ubyte[] dataVideotex = [ 0x15u, 0x06u, 0xFFu, 0x05u, 0x04u, 0x03u, 0x02u, 0x01u ];
    immutable ubyte[] dataIA5 = [ 0x16u, 0x08u, 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S' ];
    immutable ubyte[] dataUTC = [ 0x17u, 0x0Cu, '1', '7', '0', '8', '3', '1', '1', '3', '4', '5', '0', '0' ];
    immutable ubyte[] dataGT = [ 0x18u, 0x0Eu, '2', '0', '1', '7', '0', '8', '3', '1', '1', '3', '4', '5', '0', '0' ];
    immutable ubyte[] dataGraphic = [ 0x19u, 0x0Bu, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    immutable ubyte[] dataVisible = [ 0x1Au, 0x0Bu, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    immutable ubyte[] dataGeneral = [ 0x1Bu, 0x0Bu, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    immutable ubyte[] dataUniversal = [
        0x1Cu, 0x10u,
        0x00u, 0x00u, 0x00u, 0x61u,
        0x00u, 0x00u, 0x00u, 0x62u,
        0x00u, 0x00u, 0x00u, 0x63u,
        0x00u, 0x00u, 0x00u, 0x64u
    ]; // Big-endian "abcd"
    immutable ubyte[] dataCharacter = [
        0x1Du, 0x0Cu, 0x80u, 0x03u, 0x82u, 0x01u, 0x3Fu, 0x82u,
        0x05u, 0x48u, 0x45u, 0x4Eu, 0x4Cu, 0x4Fu ];
    immutable ubyte[] dataBMP = [ 0x1Eu, 0x08u, 0x00u, 0x61u, 0x00u, 0x62u, 0x00u, 0x63u, 0x00u, 0x64u ]; // Big-endian "abcd"

    // Combine it all
    ubyte[] data =
        (dataEndOfContent ~
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
        dataBMP).dup;

    BERElement[] result;

    size_t i = 0u;
    while (i < data.length)
        result ~= new BERElement(i, data);

    // Pre-processing
    External x = result[8].external;
    EmbeddedPDV m = result[11].embeddedPDV;
    CharacterString c = result[25].characterString;

    // Ensure accessors decode the data correctly.
    assert(result[1].boolean == true);
    assert(result[2].integer!long == 27L);
    assert(result[3].bitString == [ true, true, true, true, false, false, false, false, true ]);
    assert(result[4].octetString == [ 0xFFu, 0x00u, 0x88u, 0x14u ]);
    assert(result[6].objectIdentifier == new OID(OIDNode(0x01u), OIDNode(0x03u), OIDNode(0x06u), OIDNode(0x04u), OIDNode(0x01u)));
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert((x.identification.presentationContextID == 27L) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[9].realType!float == 0.15625);
    assert(result[9].realType!double == 0.15625);
    assert(result[10].enumerated!long == 63L);
    assert((m.identification.presentationContextID == 27L) && (m.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
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
    assert((c.identification.presentationContextID == 63L) && (c.stringValue == "HENLO"w));

    result = [];
    while (data.length > 0)
        result ~= new BERElement(data);

    // Pre-processing
    x = result[8].external;
    m = result[11].embeddedPresentationDataValue;
    c = result[25].characterString;

    // Ensure accessors decode the data correctly.
    assert(result[1].boolean == true);
    assert(result[2].integer!long == 27L);
    assert(result[3].bitString == [ true, true, true, true, false, false, false, false, true ]);
    assert(result[4].octetString == [ 0xFFu, 0x00u, 0x88u, 0x14u ]);
    assert(result[6].objectIdentifier == new OID(OIDNode(0x01u), OIDNode(0x03u), OIDNode(0x06u), OIDNode(0x04u), OIDNode(0x01u)));
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert((x.identification.presentationContextID == 27L) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[9].realType!float == 0.15625);
    assert(result[9].realType!double == 0.15625);
    assert(result[10].enumerated!long == 63L);
    assert((m.identification.presentationContextID == 27L) && (m.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
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
    assert((c.identification.presentationContextID == 63L) && (c.stringValue == "HENLO"w));
}

// Test of definite-long encoding
@system
unittest
{
    ubyte[] data = [ // 192 characters of boomer-posting
        0x0Cu, 0x81u, 0xC0u,
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

    BERElement[] result;
    size_t i = 0u;
    while (i < data.length)
        result ~= new BERElement(i, data);

    assert(result.length == 3);
    assert(result[0].utf8String[0 .. 5] == "AMREN");
    assert(result[1].utf8String[6 .. 14] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');

    result = [];
    while (data.length > 0)
        result ~= new BERElement(data);

    assert(result.length == 3);
    assert(result[0].utf8String[0 .. 5] == "AMREN");
    assert(result[1].utf8String[6 .. 14] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');
}

// Test of indefinite-length encoding
@system
unittest
{
    ubyte[] data = [ // 192 characters of boomer-posting
        0x2Cu, 0x80u,
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x0Cu, 0x10u, 'A', 'M', 'R', 'E', 'N', ' ', 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S', '!', '\n',
        0x00u, 0x00u
    ];

    data = (data ~ data ~ data); // Triple the data, to catch any bugs that arise with subsequent values.

    BERElement[] result;
    size_t i = 0u;
    while (i < data.length)
        result ~= new BERElement(i, data);

    assert(result.length == 3);
    assert(result[0].length == 216u);
    assert(result[0].utf8String[2 .. 7] == "AMREN");
    assert(result[1].utf8String[8 .. 16] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');

    result = [];
    while (data.length > 0)
        result ~= new BERElement(data);

    assert(result.length == 3);
    assert(result[0].utf8String[2 .. 7] == "AMREN");
    assert(result[1].utf8String[8 .. 16] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');
}

// Test deeply (but not too deeply) nested indefinite-length elements
@system
unittest
{
    ubyte[] data = [
        0x2Cu, 0x80u,
            0x2Cu, 0x80u,
                0x0Cu, 0x02u, 'H', 'I',
                0x00u, 0x00u,
            0x00u, 0x00u ];
    assertNotThrown!ASN1Exception(new BERElement(data));
}

// Test nested DL within IL within DL within IL elements
@system
unittest
{
    ubyte[] data = [
        0x2Cu, 0x80u, // IL
            0x2Cu, 0x06u, // DL
                0x2Cu, 0x80u, // IL
                    0x0Cu, 0x02u, 'H', 'I',
                    0x00u, 0x00u,
            0x00u, 0x00u ];
    assertNotThrown!ASN1Exception(new BERElement(data));
}

// Try to induce infinite recursion for an indefinite-length element
@system
unittest
{
    ubyte[] invalid = [];
    for (size_t i = 0u; i < BERElement.nestingRecursionLimit+1; i++)
    {
        invalid ~= [ 0x2Cu, 0x80u ];
    }
    assertThrown!ASN1RecursionException(new BERElement(invalid));
}

// Try to crash everything with a short indefinite-length element
@system
unittest
{
    ubyte[] invalid;
    invalid = [ 0x2Cu, 0x80u, 0x01u ];
    assertThrown!ASN1Exception(new BERElement(invalid));
    invalid = [ 0x2Cu, 0x80u, 0x00u ];
    assertThrown!ASN1Exception(new BERElement(invalid));
}

// Test an embedded value with two adjacent null octets
@system
unittest
{
    ubyte[] data = [
        0x04u, 0x80u,
            0x04u, 0x04u, 0x00u, 0x00u, 0x00u, 0x00u, // These should not indicate the end.
            0x00u, 0x00u ]; // These should.
    assert((new BERElement(data)).value == [ 0x04u, 0x04u, 0x00u, 0x00u, 0x00u, 0x00u ]);
}

// Test that a nested element must have the same tag class
@system
unittest
{
    ubyte[] invalid = [
        0x2Cu, 0x80u,
            0xACu, 0x02u, 'H', 'I', // The first byte should be 0x0Cu, not 0xACu.
            0x00u, 0x00u ];
    assertThrown!ASN1TagException(new BERElement(invalid));
}

// Test that a nested element must have the same tag number
@system
unittest
{
    ubyte[] invalid = [
        0x2Cu, 0x80u,
            0x0Du, 0x02u, 'H', 'I', // The first byte should be 0x0Cu, not 0x0Du.
            0x00u, 0x00u ];
    assertThrown!ASN1TagException(new BERElement(invalid));
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

    BERElement el;
    assertNotThrown!Exception(el = new BERElement(test));
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
        assertThrown!Exception(new BERElement(data));
    }

    size_t index;
    for (ubyte i = 0x00u; i < ubyte.max; i++)
    {
        immutable ubyte[] data = [i];
        assertThrown!Exception(new BERElement(index, data));
    }
}

@system
unittest
{
    BERElement el = new BERElement();
    el.realType!float = 1.0;
    assert(approxEqual(el.realType!float, 1.0));
    assert(approxEqual(el.realType!double, 1.0));
    el.realType!double = 1.0;
    assert(approxEqual(el.realType!float, 1.0));
    assert(approxEqual(el.realType!double, 1.0));
}

// Test long-form tag number (when # >= 31) with leading zero bytes (0x80)
@system
unittest
{
    ubyte[] invalid;
    invalid = [ 0b10011111u, 0b10000000u ];
    assertThrown!ASN1TagException(new BERElement(invalid));

    invalid = [ 0b10011111u, 0b10000000u, 0b10000000u ];
    assertThrown!ASN1TagException(new BERElement(invalid));

    invalid = [ 0b10011111u, 0b10000000u, 0b10000111u ];
    assertThrown!ASN1TagException(new BERElement(invalid));
}

// Test long-form tag numbers do not encode with leading zeroes
@system
unittest
{
    ubyte[] invalid;
    BERElement element = new BERElement();
    element.tagNumber = 73u;
    assert((element.toBytes)[1] != 0x80u);
}

// Test that a value that is a byte too short does not throw a RangeError.
@system
unittest
{
    ubyte[] test = [ 0x00u, 0x03u, 0x00u, 0x00u ];
    assertThrown!ASN1ValueTooSmallException(new BERElement(test));
}

// Test that a misleading definite-long length byte does not throw a RangeError.
@system
unittest
{
    ubyte[] invalid = [ 0b0000_0000u, 0b1000_0001u ];
    assertThrown!ASN1ValueTooSmallException(new BERElement(invalid));
}

// Test that a very large value does not cause a segfault or something
@system
unittest
{
    size_t biggest = cast(size_t) int.max;
    ubyte[] big = [ 0x00u, 0x80u ];
    big[1] += cast(ubyte) int.sizeof;
    big ~= cast(ubyte[]) *cast(ubyte[int.sizeof] *) &biggest;
    big ~= [ 0x01u, 0x02u, 0x03u ]; // Plus some arbitrary data.
    assertThrown!ASN1ValueTooSmallException(new BERElement(big));
}

// Test that the largest possible item does not cause a segfault or something
@system
unittest
{
    size_t biggest = size_t.max;
    ubyte[] big = [ 0x00u, 0x80u ];
    big[1] += cast(ubyte) size_t.sizeof;
    big ~= cast(ubyte[]) *cast(ubyte[size_t.sizeof] *) &biggest;
    big ~= [ 0x01u, 0x02u, 0x03u ]; // Plus some arbitrary data.
    assertThrown!ASN1ValueTooBigException(new BERElement(big));
}

// Test that a short indefinite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x1F, 0x00u, 0x80, 0x00u ];
    size_t bytesRead = 0u;
    assertThrown!ASN1ValueTooSmallException(new BERElement(bytesRead, naughty));
}

// Test that a short indefinite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x1F, 0x00u, 0x80, 0x00u, 0x00u ];
    size_t bytesRead = 0u;
    assertNotThrown!ASN1ValueTooSmallException(new BERElement(bytesRead, naughty));
}

// Test that a valueless long-form definite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x00u, 0x82, 0x00u, 0x01u ];
    size_t bytesRead = 0u;
    assertThrown!ASN1ValueTooSmallException(new BERElement(bytesRead, naughty));
}

// PyASN1 Comparison Testing
@system
unittest
{
    BERElement e = new BERElement();
    e.boolean = false;
    assert(e.value == [ 0x00u ]);
    e.integer = 5;
    assert(e.value == [ 0x05u ]);
    e.bitString = [
        true, false, true, true, false, false, true, true,
        true, false, false, false ];
    assert(e.value == [ 0x04u, 0xB3u, 0x80u ]);
    e.bitString = [
        true, false, true, true, false, true, false, false ];
    assert(e.value == [ 0x00u, 0xB4u ]);
    e.objectIdentifier = new OID(1, 2, 0, 256, 79999, 7);
    assert(e.value == [
        0x2Au, 0x00u, 0x82u, 0x00u, 0x84u, 0xF0u, 0x7Fu, 0x07u ]);
    e.enumerated = 5;
    assert(e.value == [ 0x05u ]);
    e.enumerated = 90000;
    assert(e.value == [ 0x01u, 0x5Fu, 0x90u ]);
}

// Test that all data types that cannot have value length = 0 throw exceptions.
// See CVE-2015-5726.
@system
unittest
{
    BERElement el = new BERElement();
    assertThrown!ASN1Exception(el.boolean);
    assertThrown!ASN1Exception(el.integer!byte);
    assertThrown!ASN1Exception(el.integer!short);
    assertThrown!ASN1Exception(el.integer!int);
    assertThrown!ASN1Exception(el.integer!long);
    assertThrown!ASN1Exception(el.bitString);
    assertThrown!ASN1Exception(el.objectIdentifier);
    assertThrown!ASN1Exception(el.enumerated!byte);
    assertThrown!ASN1Exception(el.enumerated!short);
    assertThrown!ASN1Exception(el.enumerated!int);
    assertThrown!ASN1Exception(el.enumerated!long);
    assertThrown!ASN1Exception(el.generalizedTime);
    assertThrown!ASN1Exception(el.utcTime);
}