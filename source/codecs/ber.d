/**
    Basic Encoding Rules (BER) is a standard for encoding ASN.1 data. It is by
    far the most common standard for doing so, being used in LDAP, TLS, SNMP,
    RDP, and other protocols. Like Distinguished Encoding Rules (DER),
    Canonical Encoding Rules (CER), and Packed Encoding Rules (PER), Basic
    Encoding Rules is a specification created by the
    $(LINK http://www.itu.int/en/pages/default.aspx, International Telecommunications Union),
    and specified in
    $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

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

    Authors:
    $(UL
        $(LI $(PERSON Jonathan M. Wilbur, jonathan@wilbur.space, http://jonathan.wilbur.space))
    )
    Copyright: Copyright (C) Jonathan M. Wilbur
    License: $(LINK https://mit-license.org/, MIT License)
    Standards:
    $(UL
        $(LI $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1)))
        $(LI $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules))
    )
    See_Also:
    $(UL
        $(LI $(LINK https://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One, The Wikipedia Page on ASN.1))
        $(LI $(LINK https://en.wikipedia.org/wiki/X.690, The Wikipedia Page on X.690))
        $(LI $(LINK https://www.strozhevsky.com/free_docs/asn1_in_simple_words.pdf, ASN.1 By Simple Words))
        $(LI $(LINK http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF, ASN.1: Communication Between Heterogeneous Systems))
    )
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
    $(LINK http://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s,
    $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

    $(MONO {joint-iso-itu-t asn1 (1) basic-encoding (1)} )
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

    ///
    static public LengthEncodingPreference lengthEncodingPreference =
        LengthEncodingPreference.definite;

    ///
    public ASN1TagClass tagClass;
    ///
    public ASN1Construction construction;
    ///
    public size_t tagNumber;

    /// The length of the value in octets
    public @property @safe nothrow
    size_t length() const
    {
        return this.value.length;
    }

    /**
        I have been on the fence about this for a while now: I don't want
        developers directly setting the bytes of the value. I know that making
        value a public member means that some idiot somewhere is going to
        bypass all of the methods I made and just directly set values himself,
        resulting in some catastrophic bug in a major library or program
        somewhere.

        But on the other hand, if I make value a private member, and readable
        only via property, then the same idiot that would have directly set
        value could just directly set the value using the $(D octetString) method.

        So either way, I can't stop anybody from doing something dumb with this
        code. As Ron White says: you can't fix stupid. So value is going to be
        a public member. But don't touch it.
    */
    public ubyte[] value;

    /**
        "Decodes" an $(MONO END OF CONTENT), by which I mean: returns nothing, but
        throws exceptions if the element is not correct.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueSizeException) if there are any content octets)
        )
    */
    override public @property @safe
    void endOfContent() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an END OF CONTENT");

        if (this.value.length != 0u)
            throw new ASN1ValueSizeException
            (0u, 0u, this.value.length, "decode an END OF CONTENT");
    }

    /**
        Decodes a $(D bool).

        Any non-zero value will be interpreted as $(MONO TRUE). Only zero will be
        interpreted as $(MONO FALSE).

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException)
                if the encoded value is not primitively-constructed)
            $(LI $(D ASN1ValueSizeException)
                if the encoded value is not exactly 1 byte in size)
        )
    */
    override public @property @safe
    bool boolean() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a BOOLEAN");

        if (this.value.length != 1u)
            throw new ASN1ValueSizeException
            (1u, 1u, this.value.length, "decode a BOOLEAN");

        return (this.value[0] ? true : false);
    }

    /// Encodes a $(D bool)
    override public @property @safe nothrow
    void boolean(in bool value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = [(value ? 0xFFu : 0x00u)];
    }

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

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException)
                if the encoded value is not primitively-constructed)
            $(LI $(D ASN1ValueSizeException)
                if the value is too big to decode to a signed integral type,
                or if the value is zero bytes)
            $(LI $(D ASN1ValuePaddingException)
                if there are padding bytes)
        )
    */
    public @property @system
    T integer(T)() const
    if (isIntegral!T && isSigned!T)
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an INTEGER");

        if (this.value.length == 1u)
            return cast(T) cast(byte) this.value[0];

        if (this.value.length == 0u || this.value.length > T.sizeof)
            throw new ASN1ValueSizeException
            (1u, long.sizeof, this.value.length, "decode an INTEGER");

        /* NOTE:
            this.value must be duplicated; if it is not, the reverse() operation
            below reverses this.value, which persists until the next decode!
        */
        ubyte[] value = this.value.dup;
        if
        (
            this.value.length > 1u &&
            (
                (this.value[0] == 0x00u && (!(this.value[1] & 0x80u))) || // Unnecessary positive leading bytes
                (this.value[0] == 0xFFu && (this.value[1] & 0x80u)) // Unnecessary negative leading bytes
            )
        )
            throw new ASN1ValuePaddingException
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

    /// Encodes a signed integral type
    public @property @system nothrow
    void integer(T)(in T value)
    if (isIntegral!T && isSigned!T)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        scope(success) this.construction = ASN1Construction.primitive;
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
        assertThrown!ASN1ValueSizeException(el.integer!byte);
        assertThrown!ASN1ValueSizeException(el.integer!short);
        assertThrown!ASN1ValueSizeException(el.integer!int);
        assertThrown!ASN1ValueSizeException(el.integer!long);
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
        Decodes an array of $(D bool)s representing a string of bits.

        Returns: an array of $(D bool)s, where each $(D bool) represents a bit
            in the encoded bit string

        Throws:
        $(UL
            $(LI $(D ASN1ValueSizeException)
                if the any primitive contains 0 bytes)
            $(LI $(D ASN1ValueException)
                if the first byte has a value greater
                than seven, or if the first byte indicates the presence of
                padding bits when no subsequent bytes exist, or if any primitive
                but the last in a constructed BIT STRING uses padding bits)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property
    bool[] bitString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            if (this.value.length == 0u)
                throw new ASN1ValueSizeException
                (1u, size_t.max, 0u, "decode a BIT STRING");

            if (this.value[0] > 0x07u)
                throw new ASN1ValueException
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
                throw new ASN1ValueException
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
                    (this.value[i] & 0b10000000u ? true : false),
                    (this.value[i] & 0b01000000u ? true : false),
                    (this.value[i] & 0b00100000u ? true : false),
                    (this.value[i] & 0b00010000u ? true : false),
                    (this.value[i] & 0b00001000u ? true : false),
                    (this.value[i] & 0b00000100u ? true : false),
                    (this.value[i] & 0b00000010u ? true : false),
                    (this.value[i] & 0b00000001u ? true : false)
                ];
            }
            ret.length -= this.value[0];
            return ret;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a BIT STRING");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!(bool[]) appendy = appender!(bool[])();
            BERElement[] substrings = this.sequence;
            if (substrings.length == 0u) return [];
            foreach (substring; substrings[0 .. $-1])
            {
                if
                (
                    substring.construction == ASN1Construction.primitive &&
                    substring.length > 0u &&
                    substring.value[0] != 0x00u
                )
                    throw new ASN1ValueException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a constructed BIT STRING that contained a " ~
                        "substring whose first byte indicated a non-zero " ~
                        "number of padding bits, despite not being the " ~
                        "last substring of the constructed BIT STRING. " ~
                        "Only the last substring may have padding bits. "
                    );
            }

            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed BIT STRING");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed BIT STRING");

                appendy.put(substring.bitString);
            }
            return appendy.data;
        }
    }

    /// Encodes an array of $(D bool)s representing a string of bits.
    override public @property
    void bitString(in bool[] value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        scope(success) this.construction = ASN1Construction.primitive;
        ubyte[] ub;
        ub.length = ((value.length / 8u) + (value.length % 8u ? 1u : 0u));
        for (size_t i = 0u; i < value.length; i++)
        {
            if (value[i] == false) continue;
            ub[(i/8u)] |= (0b10000000u >> (i % 8u));
        }
        this.value = [ cast(ubyte) (8u - (value.length % 8u)) ] ~ ub;
        if (this.value[0] == 0x08u) this.value[0] = 0x00u;
    }

    // Test a $(MONO BIT STRING) with a deceptive first byte.
    @system
    unittest
    {
        BERElement el = new BERElement();
        el.value = [ 0x01u ];
        assertThrown!ASN1ValueException(el.bitString);
    }

    @system
    unittest
    {
        ubyte[] data = [
            0x23u, 0x0Eu,
                0x03u, 0x02u, 0x00u, 0x0Fu,
                0x23u, 0x04u,
                    0x03u, 0x02u, 0x00u, 0x0Fu,
                0x03u, 0x02u, 0x05u, 0xF0u
        ];

        BERElement element = new BERElement(data);
        assert(element.bitString == [
            false, false, false, false, true, true, true, true,
            false, false, false, false, true, true, true, true,
            true, true, true
        ]);
    }

    @system
    unittest
    {
        ubyte[] data = [
            0x23u, 0x0Eu,
                0x03u, 0x02u, 0x03u, 0x0Fu, // Non-zero first byte!
                0x23u, 0x04u,
                    0x03u, 0x02u, 0x00u, 0x0Fu,
                0x03u, 0x02u, 0x05u, 0xF0u
        ];

        BERElement element = new BERElement(data);
        assertThrown!ASN1ValueException(element.bitString);
    }

    @system
    unittest
    {
        ubyte[] data = [
            0x23u, 0x0Cu,
                0x03u, 0x00u, // Empty first element!
                0x23u, 0x04u,
                    0x03u, 0x02u, 0x00u, 0x0Fu,
                0x03u, 0x02u, 0x05u, 0xF0u
        ];

        BERElement element = new BERElement(data);
        assertThrown!ASN1ValueSizeException(element.bitString);
    }

    /**
        Decodes an $(MONO OCTET STRING) into an unsigned byte array.

        Throws:
        $(UL
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    ubyte[] octetString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            return this.value.dup;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse an OCTET STRING");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!(ubyte[]) appendy = appender!(ubyte[])();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed OCTET STRING");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed OCTET STRING");

                appendy.put(substring.octetString);
            }
            return appendy.data;
        }
    }

    /// Encodes an $(MONO OCTET STRING) from an unsigned byte ($(D ubyte)) array.
    override public @property @safe
    void octetString(in ubyte[] value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = value.dup;
    }

    @system
    unittest
    {
        ubyte[] data = [
            0x24u, 0x11u,
                0x04u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u,
                0x24u, 0x05u,
                    0x04u, 0x03u, 0x05u, 0x06u, 0x07u,
                0x04u, 0x02u, 0x08u, 0x09u
        ];

        BERElement element = new BERElement(data);
        assert(element.octetString == [
            0x01u, 0x02u, 0x03u, 0x04u, 0x05u, 0x06u, 0x07u, 0x08u, 0x09u
        ]);
    }

    @system
    unittest
    {
        ubyte[] data = [
            0x24u, 0x11u,
                0x04u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u,
                0x24u, 0x05u,
                    0x05u, 0x03u, 0x05u, 0x06u, 0x07u, // Different Tag Number
                0x04u, 0x02u, 0x08u, 0x09u
        ];

        BERElement element = new BERElement(data);
        assertThrown!ASN1TagNumberException(element.octetString);
    }

    @system
    unittest
    {
        if (this.nestingRecursionLimit < 128u) // This test will break above this number.
        {
            ubyte[] data;
            for (size_t i = 0u; i < this.nestingRecursionLimit; i++)
            {
                data = ([ cast(ubyte) 0x24u, cast(ubyte) data.length ] ~ data);
            }
            BERElement element = new BERElement();
            element.tagNumber = 4u;
            element.construction = ASN1Construction.constructed;
            element.value = data;
            assertThrown!ASN1RecursionException(element.octetString);
        }
    }

    /**
        "Decodes" a $(D null), by which I mean: returns nothing, but
        throws exceptions if the element is not correct.

        Note:
            I had to name this method $(D nill), because $(D null) is a keyword in D.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueSizeException) if there are any content octets)
        )
    */
    override public @property @safe
    void nill() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a NULL");

        if (this.value.length != 0u)
            throw new ASN1ValueSizeException
            (0u, 0u, this.value.length, "decode a NULL");
    }

    /**
        Decodes an $(MONO OBJECT IDENTIFIER).
        See $(MONO source/types/universal/objectidentifier.d) for information about
        the $(D ObjectIdentifier) class (aliased as $(D OID)).

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValueSizeException) if there are no value bytes)
            $(LI $(D ASN1ValuePaddingException) if a single OID number is encoded with
                "leading zero bytes" ($(D 0x80u)))
            $(LI $(D ASN1ValueOverflowException) if a single OID number is too big to
                decode to a $(D size_t))
            $(LI $(D ASN1TruncationException) if a single OID number is "cut off")
        )

        Standards:
        $(UL
            $(LI $(LINK http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660))
        )
    */
    override public @property @system
    OID objectIdentifier() const
    out (value)
    {
        assert(value.length >= 2u);
    }
    body
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an OBJECT IDENTIFIER");

        if (this.value.length == 0u)
            throw new ASN1ValueSizeException
            (1u, size_t.max, 0u, "decode an OBJECT IDENTIFIER");

        if (this.value.length >= 2u)
        {
            // Skip the first, because it is fine if it is 0x80
            // Skip the last because it will be checked next
            foreach (immutable octet; this.value[1 .. $-1])
            {
                if (octet == 0x80u)
                    throw new ASN1ValuePaddingException
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
                throw new ASN1TruncationException
                (size_t.max, this.value.length, "decode an OBJECT IDENTIFIER");
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
                throw new ASN1ValueOverflowException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a OBJECT IDENTIFIER that encoded a number on more than " ~
                    "size_t.sizeof bytes. " ~
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
        Encodes an $(MONO OBJECT IDENTIFIER).
        See $(MONO source/types/universal/objectidentifier.d) for information about
        the $(D ObjectIdentifier) class (aliased as $(OID)).

        Standards:
        $(UL
            $(LI $(LINK http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660))
        )
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
        scope(success) this.construction = ASN1Construction.primitive;
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
        element.value = [ 0x29u, 0x80u, 0x14u ];
        assertThrown!ASN1ValuePaddingException(element.objectIdentifier);
        element.value = [ 0x29u, 0x80u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.objectIdentifier);
        element.value = [ 0x80u, 0x80u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.objectIdentifier);

        // Test for non-terminating components
        element.value = [ 0x29u, 0x81u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);
        element.value = [ 0x29u, 0x80u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);
        element.value = [ 0x29u, 0x14u, 0x81u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);
        element.value = [ 0x29u, 0x14u, 0x80u ];
        assertThrown!ASN1TruncationException(element.objectIdentifier);

        // This one should not fail. 0x80u is valid for the first octet.
        element.value = [ 0x80u, 0x14u, 0x14u ];
        assertNotThrown!ASN1ValuePaddingException(element.objectIdentifier);
    }

    /**
        Decodes an $(D ObjectDescriptor), which is a string consisting of only
        graphical characters. In fact, $(D ObjectDescriptor) is actually implicitly
        just a $(MONO GraphicString)! The formal specification for an $(D ObjectDescriptor)
        is:

        $(MONO ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        $(MONO GraphicString) is just a string containing only characters between
        and including $(D 0x20) and $(D 0x7E), therefore ObjectDescriptor is just
        $(D 0x20) and $(D 0x7E).

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException)
                if the encoded value contains any character outside of
                $(D 0x20) to $(D 0x7E), which means any control characters or $(MONO DELETE))
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 175-178.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    string objectDescriptor() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            foreach (immutable character; this.value)
            {
                if ((!character.isGraphical) && (character != ' '))
                    throw new ASN1ValueCharactersException
                    ("all characters within the range 0x20 to 0x7E", character, "ObjectDescriptor");
            }
            return cast(string) this.value;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse an ObjectDescriptor");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!string appendy = appender!string();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed ObjectDescriptor");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed ObjectDescriptor");

                appendy.put(substring.objectDescriptor);
            }
            return appendy.data;
        }
    }

    /**
        Encodes an $(D ObjectDescriptor), which is a string consisting of only
        graphical characters. In fact, $(D ObjectDescriptor) is actually implicitly
        just a $(MONO GraphicString)! The formal specification for an $(D ObjectDescriptor)
        is:

        $(MONO ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        $(MONO GraphicString) is just a string containing only characters between
        and including $(D 0x20) and $(D 0x7E), therefore ObjectDescriptor is just
        $(D 0x20) and $(D 0x7E).

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException)
                if the string value contains any character outside of
                $(D 0x20) to $(D 0x7E), which means any control characters or $(MONO DELETE))
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 175-178.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    void objectDescriptor(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if ((!character.isGraphical) && (character != ' '))
                throw new ASN1ValueCharactersException
                ("all characters within the range 0x20 to 0x7E", character, "ObjectDescriptor");
        }
        this.value = cast(ubyte[]) value;
    }

    @system
    unittest
    {
        ubyte[] data = [
            0x27u, 0x12u,
                0x07u, 0x04u, 'S', 'h', 'i', 'a',
                0x27u, 0x04u,
                    0x07u, 0x02u, 'L', 'a',
                0x07u, 0x04u, 'B', 'T', 'F', 'O'
        ];

        BERElement element = new BERElement(data);
        assert(element.objectDescriptor == "ShiaLaBTFO");
    }

    // Make sure that exceptions do not leave behind a residual recursion count.
    @system
    unittest
    {
        ubyte[] data = [ 0x27u, 0x03u, 0x07u, 0x01u, 0x03u ];
        for (size_t i = 0u; i <= this.nestingRecursionLimit; i++)
        {
            size_t sentinel = 0u;
            BERElement element = new BERElement(sentinel, data);
            assertThrown!ASN1ValueCharactersException(element.objectDescriptor);
        }
    }

    /**
        Decodes an $(MONO EXTERNAL).

        According to the
        $(LINK http://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1)),
        the abstract definition for an $(MONO EXTERNAL), after removing the comments in the
        specification, is as follows:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
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
                    ( WITH COMPONENTS {
                        ... ,
                        identification ( WITH COMPONENTS {
                            ... ,
                            syntaxes ABSENT,
                            transfer-syntax ABSENT,
                            fixed ABSENT } ) } )
        )

        Note that the abstract syntax resembles that of $(MONO EmbeddedPDV) and
        $(MONO CharacterString), except with a $(MONO WITH COMPONENTS) constraint that removes some
        of our choices of $(MONO identification).
        As can be seen on page 303 of Olivier Dubuisson's
        $(I $(LINK http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF,
            ASN.1: Communication Between Heterogeneous Systems)),
        after applying the $(MONO WITH COMPONENTS) constraint, our reduced syntax becomes:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER } },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        But, according to the
        $(LINK http://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules),
        section 8.18, when encoded using Basic Encoding Rules (BER), is encoded as
        follows, for compatibility reasons:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
                direct-reference  OBJECT IDENTIFIER OPTIONAL,
                indirect-reference  INTEGER OPTIONAL,
                data-value-descriptor  ObjectDescriptor  OPTIONAL,
                encoding  CHOICE {
                    single-ASN1-type  [0] ANY,
                    octet-aligned     [1] IMPLICIT OCTET STRING,
                    arbitrary         [2] IMPLICIT BIT STRING } }
        )

        The definition above is the pre-1994 definition of $(MONO EXTERNAL). The $(MONO syntax)
        field of the post-1994 definition maps to the $(MONO direct-reference) field of
        the pre-1994 definition. The $(MONO presentation-context-id) field of the post-1994
        definition maps to the $(MONO indirect-reference) field of the pre-1994 definition.
        If $(MONO context-negotiation) is used, per the abstract syntax, then the
        $(MONO presentation-context-id) field of the $(MONO context-negotiation) $(MONO SEQUENCE) in the
        post-1994 definition maps to the $(MONO indirect-reference) field of the pre-1994
        definition, and the $(MONO transfer-syntax) field of the $(MONO context-negotiation)
        $(MONO SEQUENCE) maps to the $(MONO direct-reference) field of the pre-1994 definition.

        Returns: an $(MONO External), defined in $(D types.universal.external).

        Throws:
        $(UL
            $(LI $(D ASN1ValueException)
                if the SEQUENCE does not contain two to four elements)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not have the correct tag class)
            $(LI $(D ASN1ConstructionException)
                if any element has the wrong construction)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not have the correct tag number)
            $(LI $(D ASN1ValueCharactersException)
                if a data-value-descriptor is supplied with invalid characters)
        )
    */
    deprecated override public @property @system
    External external() const
    {
        if (this.construction != ASN1Construction.constructed)
            throw new ASN1ConstructionException
            (this.construction, "decode an EXTERNAL");

        const BERElement[] components = this.sequence;
        External ext = External();
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length < 2u || components.length > 4u)
            throw new ASN1ValueException
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
                throw new ASN1TagClassException
                ([ ASN1TagClass.universal ], component.tagClass, "decode all but the last component of an EXTERNAL");
        }

        // The last tag must be context-specific class
        if (components[$-1].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            ([ ASN1TagClass.contextSpecific ], components[$-1].tagClass, "decode the last component of an EXTERNAL");

        // The first component should always be primitive
        if (components[0].construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (components[0].construction, "decode the first component of an EXTERNAL");

        if
        (
            components[0].tagNumber != ASN1UniversalType.objectIdentifier &&
            components[0].tagNumber != ASN1UniversalType.integer
        )
            throw new ASN1TagNumberException
            ([ 2u, 6u ], components[0].tagNumber, "decode the first component of an EXTERNAL");

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
                        throw new ASN1ConstructionException
                        (components[1].construction, "decode the second component of an EXTERNAL");

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

                    ext.dataValueDescriptor = components[1].objectDescriptor;
                }
                else
                    throw new ASN1TagNumberException
                    ([ 2u, 6u, 7u ], components[1].tagNumber, "decode the second component of an EXTERNAL");
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
                    throw new ASN1ValueException
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
                    throw new ASN1ConstructionException
                    (components[1].construction, "decode the second component of an EXTERNAL");

                identification.contextNegotiation = ASN1ContextNegotiation(
                    components[1].integer!ptrdiff_t,
                    components[0].objectIdentifier
                );

                ext.dataValueDescriptor = components[2].objectDescriptor;
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
                throw new ASN1TagNumberException
                ([ 0u, 1u, 2u ], components[$-1].tagNumber, "decode an EXTERNAL data-value");
        }

        ext.dataValue = components[$-1].value.dup;
        ext.identification = identification;
        return ext;
    }

    /**
        Decodes an $(MONO EXTERNAL).

        According to the
        $(LINK http://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1)),
        the abstract definition for an $(MONO EXTERNAL), after removing the comments in the
        specification, is as follows:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
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
                    ( WITH COMPONENTS {
                        ... ,
                        identification ( WITH COMPONENTS {
                            ... ,
                            syntaxes ABSENT,
                            transfer-syntax ABSENT,
                            fixed ABSENT } ) } )
        )

        Note that the abstract syntax resembles that of $(MONO EmbeddedPDV) and
        $(MONO CharacterString), except with a $(MONO WITH COMPONENTS) constraint that removes some
        of our choices of $(MONO identification).
        As can be seen on page 303 of Olivier Dubuisson's
        $(I $(LINK http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF,
            ASN.1: Communication Between Heterogeneous Systems)),
        after applying the $(MONO WITH COMPONENTS) constraint, our reduced syntax becomes:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER } },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
        )

        But, according to the
        $(LINK http://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
        $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules),
        section 8.18, when encoded using Basic Encoding Rules (BER), is encoded as
        follows, for compatibility reasons:

        $(PRE
            EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
                direct-reference  OBJECT IDENTIFIER OPTIONAL,
                indirect-reference  INTEGER OPTIONAL,
                data-value-descriptor  ObjectDescriptor  OPTIONAL,
                encoding  CHOICE {
                    single-ASN1-type  [0] ANY,
                    octet-aligned     [1] IMPLICIT OCTET STRING,
                    arbitrary         [2] IMPLICIT BIT STRING } }
        )

        The definition above is the pre-1994 definition of $(MONO EXTERNAL). The $(MONO syntax)
        field of the post-1994 definition maps to the $(MONO direct-reference) field of
        the pre-1994 definition. The $(MONO presentation-context-id) field of the post-1994
        definition maps to the $(MONO indirect-reference) field of the pre-1994 definition.
        If $(MONO context-negotiation) is used, per the abstract syntax, then the
        $(MONO presentation-context-id) field of the $(MONO context-negotiation) $(MONO SEQUENCE) in the
        post-1994 definition maps to the $(MONO indirect-reference) field of the pre-1994
        definition, and the $(MONO transfer-syntax) field of the $(MONO context-negotiation)
        $(MONO SEQUENCE) maps to the $(MONO direct-reference) field of the pre-1994 definition.

        Returns: an instance of $(D types.universal.external.External)

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException)
                if a data-value-descriptor is supplied with invalid characters)
        )
    */
    deprecated override public @property @system
    void external(in External value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        scope(success) this.construction = ASN1Construction.constructed;
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
                0x81u, 0x04u, 0x01u, 0x02u, 0x03u, 0x04u // OCTET STRING 1,2,3,4
        ];

        // Valid values for octet[2]: 02 06
        for (ubyte i = 0x07u; i < 0x1Eu; i++)
        {
            external[2] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, external);
            assertThrown!ASN1Exception(el.external);
        }

        // Valid values for octet[5]: 80 - 82 (Anything else is an invalid value)
        for (ubyte i = 0x82u; i < 0x9Eu; i++)
        {
            external[5] = i;
            size_t x = 0u;
            BERElement el = new BERElement(x, external);
            assertThrown!ASN1Exception(el.external);
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
        Decodes a floating-point type.

        Note that this method assumes that your machine uses
        $(LINK http://ieeexplore.ieee.org/document/4610935/, IEEE 754-2008)
        floating point format.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1TruncationException) if the value appears to be "cut off")
            $(LI $(D ConvException) if character-encoding cannot be converted to
                the selected floating-point type, T)
            $(LI $(D ConvOverflowException) if the character-encoding encodes a
                number that is too big for the selected floating-point
                type to express)
            $(LI $(D ASN1ValueSizeException) if the binary-encoding contains fewer
                bytes than the information byte purports, or if the
                binary-encoded mantissa is too big to be expressed by an
                unsigned long integer)
            $(LI $(D ASN1ValueException) if a complicated-form exponent or a
                non-zero-byte mantissa encodes a zero)
            $(LI $(D ASN1ValueUndefinedException) if both bits indicating the base in the
                information byte of a binary-encoded $(MONO REAL)'s information byte
                are set, which would indicate an invalid base, or if a special
                value has been indicated that is not defined by the specification)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 400-402.)
            $(LI $(LINK https://www.iso.org/standard/12285.html, ISO 6093))
        )
    */
    public @property @system
    T realNumber(T)() const
    if (isFloatingPoint!T)
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a REAL");

        if (this.value.length == 0u) return cast(T) 0.0;
        switch (this.value[0] & 0b11000000u)
        {
            case (0b01000000u): // Special value
            {
                if (this.value[0] == ASN1SpecialRealValue.notANumber) return T.nan;
                if (this.value[0] == ASN1SpecialRealValue.minusZero) return -0.0;
                if (this.value[0] == ASN1SpecialRealValue.plusInfinity) return T.infinity;
                if (this.value[0] == ASN1SpecialRealValue.minusInfinity) return -T.infinity;
                throw new ASN1ValueUndefinedException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a REAL whose information byte indicated a special value " ~
                    "not recognized by the specification. The only special " ~
                    "values recognized by the specification are PLUS-INFINITY, " ~
                    "MINUS-INFINITY, NOT-A-NUMBER, and minus zero, identified " ~
                    "by information bytes of 0x40, 0x41 0x42, 0x43 respectively. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~
                    debugInformationText ~ reportBugsText
                );
            }
            case (0b00000000u): // Character Encoding
            {
                import std.conv : to;
                import std.string : stripLeft;
                string numericRepresentation = cast(string) this.value[1 .. $];
                numericRepresentation = numericRepresentation
                    .stripLeft()
                    .replace(",", ".");
                return to!(T)(numericRepresentation);
            }
            case 0b10000000u, 0b11000000u: // Binary Encoding
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
                        if (this.value.length < 3u)
                            throw new ASN1TruncationException
                            (3u, this.value.length, "decode a REAL exponent");

                        exponent = cast(short) cast(byte) this.value[1];
                        startOfMantissa = 2u;
                        break;
                    }
                    case 0b00000001u: // Exponent on the following two octets
                    {
                        if (this.value.length < 4u)
                            throw new ASN1TruncationException
                            (4u, this.value.length, "decode a REAL exponent");

                        ubyte[] exponentBytes = this.value[1 .. 3].dup;
                        version (LittleEndian) exponentBytes = [ exponentBytes[1], exponentBytes[0] ];
                        exponent = *cast(short *) exponentBytes.ptr;
                        startOfMantissa = 3u;
                        break;
                    }
                    case 0b00000010u: // Exponent on the following three octets
                    {
                        if (this.value.length < 5u)
                            throw new ASN1TruncationException
                            (5u, this.value.length, "decode a REAL exponent");

                        ubyte[] exponentBytes = this.value[1 .. 4].dup;

                        if // the first byte is basically meaningless padding
                        (
                            (this.value[0] == 0x00u && (!(this.value[1] & 0x80u))) || // Unnecessary positive leading bytes
                            (this.value[0] == 0xFFu && (this.value[1] & 0x80u)) // Unnecessary negative leading bytes
                        )
                        { // then it is small enough to become an IEEE 754 floating point type.
                            exponentBytes = exponentBytes[1 .. $];
                            exponentBytes = [ exponentBytes[1], exponentBytes[0] ];
                            exponent = *cast(short *) exponentBytes.ptr;
                            startOfMantissa = 4u;
                        }
                        else
                        {
                            throw new ASN1ValueOverflowException
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
                    case 0b00000011u: // Complicated
                    {
                        /* NOTE:
                            X.690 states that, in this case, the exponent must
                            be encoded on the fewest possible octets, even for
                            the Basic Encoding Rules (BER).
                        */

                        if (this.value.length < 4u)
                            throw new ASN1TruncationException
                            (4u, this.value.length, "decode a REAL exponent");

                        immutable ubyte exponentLength = this.value[1];

                        if (exponentLength == 0u)
                            throw new ASN1ValueException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL whose exponent was encoded on " ~
                                "zero bytes, which is prohibited by the X.690 " ~
                                "specification, section 8.5.6.4, note D. "
                            );

                        if (exponentLength > (this.length + 2u))
                            throw new ASN1TruncationException
                            (
                                exponentLength,
                                (this.length + 2u),
                                "decode a REAL from too few bytes to decode its exponent"
                            );

                        if (exponentLength > 2u)
                            throw new ASN1ValueOverflowException
                            (
                                "This exception was thrown because you attempted " ~
                                "to decode a REAL that had an exponent that was " ~
                                "too big to decode to a floating-point type. " ~
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
                            if (exponent == 0u)
                                throw new ASN1ValueException
                                (
                                    "This exception was thrown because you " ~
                                    "attempted to decode a REAL whose exponent " ~
                                    "was encoded using the complicated form " ~
                                    "described in specification X.690, section " ~
                                    "8.5.6.4.d, but whose exponent was zero, " ~
                                    "which is prohibited when using the " ~
                                    "complicated exponent encoding form, as " ~
                                    "described in section 8.5.6.4.d. "
                                );
                        }
                        else // length == 2
                        {
                            ubyte[] exponentBytes = this.value[2 .. 4].dup;

                            if
                            (
                                (exponentBytes[0] == 0x00u && (!(exponentBytes[1] & 0x80u))) || // Unnecessary positive leading bytes
                                (exponentBytes[0] == 0xFFu && (exponentBytes[1] & 0x80u)) // Unnecessary negative leading bytes
                            )
                                throw new ASN1ValuePaddingException
                                (
                                    "This exception was thrown because you attempted to decode " ~
                                    "a REAL exponent that was encoded on more than the minimum " ~
                                    "necessary bytes. " ~
                                    notWhatYouMeantText ~ forMoreInformationText ~
                                    debugInformationText ~ reportBugsText
                                );

                            version (LittleEndian) exponentBytes = [ exponentBytes[1], exponentBytes[0] ];
                            exponent = *cast(short *) exponentBytes.ptr;
                        }
                        startOfMantissa = (2u + exponentLength);
                        break;
                    }
                    default: assert(0, "Impossible binary exponent encoding on REAL type");
                }

                if (this.value.length - startOfMantissa > ulong.sizeof)
                    throw new ASN1ValueOverflowException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a REAL whose mantissa was encoded on too many " ~
                        "bytes to decode to the largest unsigned integral data " ~
                        "type. "
                    );

                ubyte[] mantissaBytes = this.value[startOfMantissa .. $].dup;
                while (mantissaBytes.length < ulong.sizeof)
                    mantissaBytes = (0x00u ~ mantissaBytes);
                version (LittleEndian) reverse(mantissaBytes);
                version (unittest) assert(mantissaBytes.length == ulong.sizeof);
                mantissa = *cast(ulong *) mantissaBytes.ptr;

                if (mantissa == 0u)
                    throw new ASN1ValueException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a REAL that was encoded on more than zero " ~
                        "bytes, but whose mantissa encoded a zero. This " ~
                        "is prohibited by specification X.690. If the " ~
                        "abstract value encoded is a real number of zero, " ~
                        "the REAL must be encoded upon zero bytes. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                switch (this.value[0] & 0b00110000u)
                {
                    case (0b00000000u): base = 0x02u; break;
                    case (0b00010000u): base = 0x08u; break;
                    case (0b00100000u): base = 0x10u; break;
                    default:
                        throw new ASN1ValueUndefinedException
                        (
                            "This exception was thrown because you attempted to " ~
                            "decode a REAL that had both base bits in the " ~
                            "information block set, the meaning of which is " ~
                            "not specified. " ~
                            notWhatYouMeantText ~ forMoreInformationText ~
                            debugInformationText ~ reportBugsText
                        );
                }

                scale = ((this.value[0] & 0b00001100u) >> 2);

                /*
                    For some reason that I have yet to discover, you must
                    cast the exponent to T. If you do not, specifically
                    any usage of realNumber!T() outside of this library will
                    produce a "floating point exception 8" message and
                    crash. For some reason, all of the tests pass within
                    this library without doing this.
                */
                return (
                    ((this.value[0] & 0b01000000u) ? -1.0 : 1.0) *
                    cast(T) mantissa *
                    2^^scale *
                    (cast(T) base)^^(cast(T) exponent) // base must be cast
                );
            }
            default: assert(0, "Impossible information byte value appeared!");
        }
    }

    /**
        Encodes a floating-point type, using base-2 binary encoding.

        Note that this method assumes that your machine uses
        $(LINK http://ieeexplore.ieee.org/document/4610935/, IEEE 754-2008)
        floating point format.

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 400-402.)
            $(LI $(LINK https://www.iso.org/standard/12285.html, ISO 6093))
        )
    */
    public @property @system nothrow
    void realNumber(T)(in T value)
    if (isFloatingPoint!T)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        /* NOTE:
            You must use isIdentical() to compare FP types to negative zero,
            because the basic == operator does not distinguish between zero
            and negative zero.

            isNaN() must be used to compare NaNs, because comparison using ==
            does not work for that at all.

            Also, this cannot go in a switch statement, because FP types
            cannot be the switch value.
        */
        if (isIdentical(value, 0.0))
        {
            this.value = [];
            return;
        }
        else if (isIdentical(value, -0.0))
        {
            this.value = [ ASN1SpecialRealValue.minusZero ];
            return;
        }
        if (value.isNaN)
        {
            this.value = [ ASN1SpecialRealValue.notANumber ];
            return;
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

        real realValue = cast(real) value;
        bool positive = true;
        ulong mantissa;
        short exponent;

        /*
            Per the IEEE specifications, the exponent of a floating-point
            type is stored with a bias, meaning that the exponent counts
            up from a negative number, the reaches zero at the bias. We
            subtract the bias from the raw binary exponent to get the
            actual exponent encoded in the IEEE floating-point number.
            In the case of an x86 80-bit extended-precision floating-point
            type, the bias is 16383. In the case of double-precision, it is
            1023. For single-precision, it is 127.

            We then subtract the number of bits in the fraction from the
            exponent, which is equivalent to having had multiplied the
            fraction enough to have made it an integer represented by the
            same sequence of bits.
        */
        ubyte[] realBytes;
        realBytes.length = real.sizeof;
        *cast(real *)&realBytes[0] = realValue;

        version (BigEndian)
        {
            static if (real.sizeof > 10u) realBytes = realBytes[real.sizeof-10 .. $];
            positive = ((realBytes[0] & 0x80u) ? false : true);
        }
        else version (LittleEndian)
        {
            static if (real.sizeof > 10u) realBytes.length = 10u;
            positive = ((realBytes[$-1] & 0x80u) ? false : true);
        }
        else assert(0, "Could not determine endianness");

        static if (real.mant_dig == 64) // x86 Extended Precision
        {
            version (BigEndian)
            {
                exponent = (((*cast(short *) &realBytes[0]) & 0x7FFF) - 16383 - 63); // 16383 is the bias
                mantissa = *cast(ulong *) &realBytes[2];
            }
            else version (LittleEndian)
            {
                exponent = (((*cast(short *) &realBytes[8]) & 0x7FFF) - 16383 - 63); // 16383 is the bias
                mantissa = *cast(ulong *) &realBytes[0];
            }
            else assert(0, "Could not determine endianness");
        }
        else if (T.mant_dig == 53) // Double Precision
        {
            /*
                The IEEE 754 double-precision floating point type only stores
                the fractional part of the mantissa, because there is an
                implicit 1 prior to the fractional part. To retrieve the actual
                mantissa encoded, we flip the bit that comes just before the
                most significant bit of the fractional part of the number.
            */
            version (BigEndian)
            {
                exponent = (((*cast(short *) &realBytes[0]) & 0x7FFF) - 1023 - 53); // 1023 is the bias
                mantissa = (((*cast(ulong *) &realBytes[2]) & 0x000FFFFFFFFFFFFFu) | 0x0010000000000000u);
            }
            else version (LittleEndian)
            {
                exponent = (((*cast(short *) &realBytes[8]) & 0x7FFF) - 1023 - 53); // 1023 is the bias
                mantissa = (((*cast(ulong *) &realBytes[0]) & 0x000FFFFFFFFFFFFFu) | 0x0010000000000000u);
            }
            else assert(0, "Could not determine endianness");
        }
        else if (T.mant_dig == 24) // Single Precision
        {
            /*
                The IEEE 754 single-precision floating point type only stores
                the fractional part of the mantissa, because there is an
                implicit 1 prior to the fractional part. To retrieve the actual
                mantissa encoded, we flip the bit that comes just before the
                most significant bit of the fractional part of the number.
            */
            version (BigEndian)
            {
                exponent = ((((*cast(short *) &realBytes[0]) & 0x7F80) >> 7) - 127 - 23); // 127 is the bias
                mantissa = cast(ulong) (((*cast(uint *) &realBytes[2]) & 0x007FFFFFu) | 0x00800000u);
            }
            else version (LittleEndian)
            {
                exponent = ((((*cast(short *) &realBytes[8]) & 0x7F80) >> 7) - 127 - 23); // 127 is the bias
                mantissa = cast(ulong) (((*cast(uint *) &realBytes[0]) & 0x007FFFFFu) | 0x00800000u);
            }
            else assert(0, "Could not determine endianness");
        }
        else assert(0, "Unrecognized real floating-point format.");

        ubyte[] exponentBytes;
        exponentBytes.length = short.sizeof;
        *cast(short *)exponentBytes.ptr = exponent;
        version (LittleEndian) exponentBytes = [ exponentBytes[1], exponentBytes[0] ]; // Manual reversal (optimization)

        ubyte[] mantissaBytes;
        mantissaBytes.length = ulong.sizeof;
        *cast(ulong *)mantissaBytes.ptr = cast(ulong) mantissa;
        version (LittleEndian) reverse(mantissaBytes);

        ubyte infoByte =
            0x80u | // First bit gets set for base2, base8, or base16 encoding
            (positive ? 0x00u : 0x40u) | // 1 = negative, 0 = positive
            // Scale = 0
            cast(ubyte) (exponentBytes.length == 1u ?
                ASN1RealExponentEncoding.followingOctet :
                ASN1RealExponentEncoding.following2Octets);

        this.value = (infoByte ~ exponentBytes ~ mantissaBytes);
    }

    @system
    unittest
    {
        BERElement el = new BERElement();

        // float
        el.realNumber!float = cast(float) float.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!double = cast(double) float.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!real = cast(real) float.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);

        el.realNumber!float = cast(float) 0.0;
        assert(el.value == []);
        el.realNumber!double = cast(float) 0.0;
        assert(el.value == []);
        el.realNumber!real = cast(float) 0.0;
        assert(el.value == []);

        el.realNumber!float = cast(float) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!double = cast(float) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!real = cast(float) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);

        el.realNumber!float = cast(float) float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!double = cast(double) float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!real = cast(real) float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);

        el.realNumber!float = cast(float) -float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!double = cast(double) -float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!real = cast(real) -float.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);

        // double
        el.realNumber!float = cast(float) double.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!double = cast(double) double.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!real = cast(real) double.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);

        el.realNumber!float = cast(double) 0.0;
        assert(el.value == []);
        el.realNumber!double = cast(double) 0.0;
        assert(el.value == []);
        el.realNumber!real = cast(double) 0.0;
        assert(el.value == []);

        el.realNumber!float = cast(double) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!double = cast(double) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!real = cast(double) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);

        el.realNumber!float = cast(float) double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!double = cast(double) double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!real = cast(real) double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);

        el.realNumber!float = cast(float) -double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!double = cast(double) -double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!real = cast(real) -double.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);

        // real
        el.realNumber!float = cast(float) real.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!double = cast(double) real.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);
        el.realNumber!real = cast(real) real.nan;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.notANumber ]);

        el.realNumber!float = cast(real) 0.0;
        assert(el.value == []);
        el.realNumber!double = cast(real) 0.0;
        assert(el.value == []);
        el.realNumber!real = cast(real) 0.0;
        assert(el.value == []);

        el.realNumber!float = cast(real) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!double = cast(real) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);
        el.realNumber!real = cast(real) -0.0;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusZero ]);

        el.realNumber!float = cast(float) real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!double = cast(double) real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);
        el.realNumber!real = cast(real) real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.plusInfinity ]);

        el.realNumber!float = cast(float) -real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!double = cast(double) -real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
        el.realNumber!real = cast(real) -real.infinity;
        assert(el.value == [ cast(ubyte) ASN1SpecialRealValue.minusInfinity ]);
    }

    // Testing Base-10 (Character-Encoded) REALs - NR1 format
    @system
    unittest
    {
        BERElement el = new BERElement();
        ubyte infoByte = 0x01u;

        el.value = [ infoByte ] ~ cast(ubyte[]) "3";
        assert(approxEqual(el.realNumber!float, 3.0));
        assert(approxEqual(el.realNumber!double, 3.0));
        assert(approxEqual(el.realNumber!real, 3.0));

        el.value = [ infoByte ] ~ cast(ubyte[]) "-1";
        assert(approxEqual(el.realNumber!float, -1.0));
        assert(approxEqual(el.realNumber!double, -1.0));
        assert(approxEqual(el.realNumber!real, -1.0));

        el.value = [ infoByte ] ~ cast(ubyte[]) "+1000";
        assert(approxEqual(el.realNumber!float, 1000.0));
        assert(approxEqual(el.realNumber!double, 1000.0));
        assert(approxEqual(el.realNumber!real, 1000.0));
    }

    // Testing Base-10 (Character-Encoded) REALs - NR2 format
    @system
    unittest
    {
        BERElement el = new BERElement();
        ubyte infoByte = 0x02u;

        el.value = [ infoByte ] ~ cast(ubyte[]) "3.0";
        assert(approxEqual(el.realNumber!float, 3.0));
        assert(approxEqual(el.realNumber!double, 3.0));
        assert(approxEqual(el.realNumber!real, 3.0));

        el.value = [ infoByte ] ~ cast(ubyte[]) "-1.3";
        assert(approxEqual(el.realNumber!float, -1.3));
        assert(approxEqual(el.realNumber!double, -1.3));
        assert(approxEqual(el.realNumber!real, -1.3));

        el.value = [ infoByte ] ~ cast(ubyte[]) "-.3";
        assert(approxEqual(el.realNumber!float, -0.3));
        assert(approxEqual(el.realNumber!double, -0.3));
        assert(approxEqual(el.realNumber!real, -0.3));
    }

    // Testing Base-10 (Character-Encoded) REALs - NR3 format
    @system
    unittest
    {
        BERElement el = new BERElement();
        ubyte infoByte = 0x03u;

        el.value = [ infoByte ] ~ cast(ubyte[]) "3.0E1";
        assert(approxEqual(el.realNumber!float, 30.0));
        assert(approxEqual(el.realNumber!double, 30.0));
        assert(approxEqual(el.realNumber!real, 30.0));

        el.value = [ infoByte ] ~ cast(ubyte[]) "123E+10";
        assert(approxEqual(el.realNumber!float, 123E10));
        assert(approxEqual(el.realNumber!double, 123E10));
        assert(approxEqual(el.realNumber!real, 123E10));
    }

    // Testing the nuances of character encoding
    @system
    unittest
    {
        BERElement el = new BERElement();
        ubyte infoByte = 0x01u;

        // Leading Spaces
        el.value = [ infoByte ] ~ cast(ubyte[]) "   +1000";
        assert(approxEqual(el.realNumber!float, 1000.0));
        assert(approxEqual(el.realNumber!double, 1000.0));
        assert(approxEqual(el.realNumber!real, 1000.0));
        el.value = [ infoByte ] ~ cast(ubyte[]) "   1000";
        assert(approxEqual(el.realNumber!float, 1000.0));
        assert(approxEqual(el.realNumber!double, 1000.0));
        assert(approxEqual(el.realNumber!real, 1000.0));

        // Leading zeros
        el.value = [ infoByte ] ~ cast(ubyte[]) "0001000";
        assert(approxEqual(el.realNumber!float, 1000.0));
        assert(approxEqual(el.realNumber!double, 1000.0));
        assert(approxEqual(el.realNumber!real, 1000.0));
        el.value = [ infoByte ] ~ cast(ubyte[]) "+0001000";
        assert(approxEqual(el.realNumber!float, 1000.0));
        assert(approxEqual(el.realNumber!double, 1000.0));
        assert(approxEqual(el.realNumber!real, 1000.0));

        // Comma instead of period
        el.value = [ infoByte ] ~ cast(ubyte[]) "0001000,23";
        assert(approxEqual(el.realNumber!float, 1000.23));
        assert(approxEqual(el.realNumber!double, 1000.23));
        assert(approxEqual(el.realNumber!real, 1000.23));
        el.value = [ infoByte ] ~ cast(ubyte[]) "+0001000,23";
        assert(approxEqual(el.realNumber!float, 1000.23));
        assert(approxEqual(el.realNumber!double, 1000.23));
        assert(approxEqual(el.realNumber!real, 1000.23));

        // A complete abomination
        el.value = [ infoByte ] ~ cast(ubyte[]) "  00123,4500e0010";
        assert(approxEqual(el.realNumber!float, 123.45e10));
        assert(approxEqual(el.realNumber!double, 123.45e10));
        assert(approxEqual(el.realNumber!real, 123.45e10));
        el.value = [ infoByte ] ~ cast(ubyte[]) "  +00123,4500e+0010";
        assert(approxEqual(el.realNumber!float, 123.45e10));
        assert(approxEqual(el.realNumber!double, 123.45e10));
        assert(approxEqual(el.realNumber!real, 123.45e10));
        el.value = [ infoByte ] ~ cast(ubyte[]) "  -00123,4500e+0010";
        assert(approxEqual(el.realNumber!float, -123.45e10));
        assert(approxEqual(el.realNumber!double, -123.45e10));
        assert(approxEqual(el.realNumber!real, -123.45e10));
    }

    // Test "complicated" exponent encoding.
    @system
    unittest
    {
        BERElement el = new BERElement();

        // Ensure that a well-formed complicated-form exponent decodes correctly.
        el.value = [ 0b10000011u, 0x01u, 0x05u, 0x03u ];
        assert(el.realNumber!float == 96.0);
        assert(el.realNumber!double == 96.0);
        assert(el.realNumber!real == 96.0);

        // Ditto, but with a negative exponent
        el.value = [ 0b10000011u, 0x01u, 0xFBu, 0x03u ];
        assert(el.realNumber!float == 0.09375);
        assert(el.realNumber!double == 0.09375);
        assert(el.realNumber!real == 0.09375);

        // Ditto, but with an exponent that spans two octets.
        el.value = [ 0b10000011u, 0x02u, 0x01u, 0x00u, 0x01u ];
        assert(approxEqual(el.realNumber!double, 2.0^^256.0));
        assert(approxEqual(el.realNumber!real, 2.0^^256.0));

        // Ensure that a zero cannot be encoded on complicated form
        el.value = [ 0b10000011u, 0x01u, 0x00u, 0x03u ];
        assertThrown!ASN1ValueException(el.realNumber!float);
        assertThrown!ASN1ValueException(el.realNumber!double);
        assertThrown!ASN1ValueException(el.realNumber!real);

        // Ensure that the complicated-form exponent must be encoded on the fewest bytes
        el.value = [ 0b10000011u, 0x02u, 0x00u, 0x05u, 0x03u ];
        assertThrown!ASN1ValuePaddingException(el.realNumber!float);
        assertThrown!ASN1ValuePaddingException(el.realNumber!double);
        assertThrown!ASN1ValuePaddingException(el.realNumber!real);

        // Ensure that large values fail
        el.value = [ 0b10000011u ];
        el.value ~= cast(ubyte) size_t.sizeof;
        el.value.length += size_t.sizeof;
        el.value[$-1] = 0x05u;
        el.value ~= 0x03u;
        assertThrown!ASN1ValueOverflowException(el.realNumber!float);
        assertThrown!ASN1ValueOverflowException(el.realNumber!double);
        assertThrown!ASN1ValueOverflowException(el.realNumber!real);
    }

    /**
        Decodes a signed integer, which represents a selection from an
        $(MONO ENUMERATION) of choices.

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException)
                if the encoded value is not primitively-constructed)
            $(LI $(D ASN1ValueSizeException)
                if the value is too big to decode to a signed integral type,
                or if the value is zero bytes)
            $(LI $(D ASN1ValuePaddingException)
                if there are padding bytes)
        )
    */
    public @property @system
    T enumerated(T)() const
    if (isIntegral!T && isSigned!T)
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode an ENUMERATED");

        if (this.value.length == 1u)
            return cast(T) cast(byte) this.value[0];

        if (this.value.length == 0u || this.value.length > T.sizeof)
            throw new ASN1ValueSizeException
            (1u, long.sizeof, this.value.length, "decode an ENUMERATED");

        /* NOTE:
            this.value must be duplicated; if it is not, the reverse() operation
            below reverses this.value, which persists until the next decode!
        */
        ubyte[] value = this.value.dup;
        if
        (
            this.value.length > 1u &&
            (
                (this.value[0] == 0x00u && (!(this.value[1] & 0x80u))) || // Unnecessary positive leading bytes
                (this.value[0] == 0xFFu && (this.value[1] & 0x80u)) // Unnecessary negative leading bytes
            )
        )
            throw new ASN1ValuePaddingException
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

    /// Encodes an $(MONO ENUMERATED) type from an integer.
    public @property @system nothrow
    void enumerated(T)(in T value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        scope(success) this.construction = ASN1Construction.primitive;
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
        assertThrown!ASN1ValueSizeException(el.enumerated!byte);
        assertThrown!ASN1ValueSizeException(el.enumerated!short);
        assertThrown!ASN1ValueSizeException(el.enumerated!int);
        assertThrown!ASN1ValueSizeException(el.enumerated!long);
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
        Decodes an $(MONO EmbeddedPDV), which is a constructed data type, defined in
            the $(LINK https://www.itu.int, International Telecommunications Union)'s
            $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines $(MONO EmbeddedPDV) as:

        $(PRE
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

        This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
        choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.

        Returns: an instance of $(D types.universal.embeddedpdv.EmbeddedPDV)

        Throws:
        $(UL
            $(LI $(D ASN1ValueException) if encoded EmbeddedPDV has too few or too many
                elements, or if syntaxes or context-negotiation element has
                too few or too many elements)
            $(LI $(D ASN1ValueSizeException) if encoded INTEGER is too large to decode)
            $(LI $(D ASN1RecursionException) if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException) if any nested primitives do not have the
                correct tag class)
            $(LI $(D ASN1ConstructionException) if any element has the wrong construction)
            $(LI $(D ASN1TagNumberException) if any nested primitives do not have the
                correct tag number)
        )
    */
    override public @property @system
    EmbeddedPDV embeddedPresentationDataValue() const
    {
        if (this.construction != ASN1Construction.constructed)
            throw new ASN1ConstructionException
            (this.construction, "decode an EmbeddedPDV");

        const BERElement[] components = this.sequence;
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length != 2u)
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EmbeddedPDV that contained too many or too few elements. " ~
                "An EmbeddedPDV should have only two elements: " ~
                "an identification CHOICE, and a data-value OCTET STRING, " ~
                "in that order. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        if (components[0].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            (
                [ ASN1TagClass.contextSpecific ],
                components[0].tagClass,
                "decode the first component of an EmbeddedPDV"
            );

        if (components[1].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            (
                [ ASN1TagClass.contextSpecific ],
                components[1].tagClass,
                "decode the second component of an EmbeddedPDV"
            );

        /* NOTE:
            See page 224 of Dubuisson, item 11:
            It sounds like, even if you have an ABSENT constraint applied,
            all automatically-tagged items still have the same numbers as
            though the constrained component were PRESENT.
        */
        if (components[0].tagNumber != 0u)
            throw new ASN1TagNumberException
            ([ 0u ], components[0].tagNumber, "decode the first component of an EmbeddedPDV");

        if (components[1].tagNumber != 2u)
            throw new ASN1TagNumberException
            ([ 2u ], components[1].tagNumber, "decode the second component of an EmbeddedPDV");

        ubyte[] bytes = components[0].value.dup;
        const BERElement identificationChoice = new BERElement(bytes);
        switch (identificationChoice.tagNumber)
        {
            case (0u): // syntaxes
            {
                if (identificationChoice.construction != ASN1Construction.constructed)
                    throw new ASN1ConstructionException
                    (identificationChoice.construction, "decode the syntaxes component of an EmbeddedPDV");

                const BERElement[] syntaxesComponents = identificationChoice.sequence;

                if (syntaxesComponents.length != 2u)
                    throw new ASN1ValueException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EmbeddedPDV whose syntaxes component " ~
                        "contained an invalid number of elements. The " ~
                        "syntaxes component should contain abstract and transfer " ~
                        "syntax OBJECT IDENTIFIERS, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                // Class Validation
                if (syntaxesComponents[0].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        syntaxesComponents[0].tagClass,
                        "decode the first syntaxes component of an EmbeddedPDV"
                    );

                if (syntaxesComponents[1].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        syntaxesComponents[1].tagClass,
                        "decode the second syntaxes component of an EmbeddedPDV"
                    );

                // Construction Validation
                if (syntaxesComponents[0].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (syntaxesComponents[0].construction, "decode the first syntaxes component of an EmbeddedPDV");

                if (syntaxesComponents[1].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (syntaxesComponents[1].construction, "decode the second syntaxes component of an EmbeddedPDV");

                // Number Validation
                if (syntaxesComponents[0].tagNumber != 0u)
                    throw new ASN1TagNumberException
                    (
                        [ 0u ],
                        syntaxesComponents[0].tagNumber,
                        "decode the first syntaxes component of an EmbeddedPDV"
                    );

                if (syntaxesComponents[1].tagNumber != 1u)
                    throw new ASN1TagNumberException
                    (
                        [ 1u ],
                        syntaxesComponents[1].tagNumber,
                        "decode the second syntaxes component of an EmbeddedPDV"
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
                if (identificationChoice.construction != ASN1Construction.constructed)
                    throw new ASN1ConstructionException
                    (identificationChoice.construction, "decode the context-negotiation component of an EmbeddedPDV");

                const BERElement[] contextNegotiationComponents = identificationChoice.sequence;

                if (contextNegotiationComponents.length != 2u)
                    throw new ASN1ValueException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an EmbeddedPDV whose context-negotiation " ~
                        "contained an invalid number of elements. The " ~
                        "context-negotiation component should contain a " ~
                        "presentation-context-id INTEGER and transfer-syntax " ~
                        "OBJECT IDENTIFIER in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                // Class Validation
                if (contextNegotiationComponents[0].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        contextNegotiationComponents[0].tagClass,
                        "decode the first context-negotiation component of an EmbeddedPDV"
                    );

                if (contextNegotiationComponents[1].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        contextNegotiationComponents[1].tagClass,
                        "decode the second context-negotiation component of an EmbeddedPDV"
                    );

                // Construction Validation
                if (contextNegotiationComponents[0].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (
                        contextNegotiationComponents[0].construction,
                        "decode the first context-negotiation component of an EmbeddedPDV"
                    );

                if (contextNegotiationComponents[1].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (
                        contextNegotiationComponents[1].construction,
                        "decode the second context-negotiation component of an EmbeddedPDV"
                    );

                // Number Validation
                if (contextNegotiationComponents[0].tagNumber != 0u)
                    throw new ASN1TagNumberException
                    (
                        [ 0u ],
                        contextNegotiationComponents[0].tagNumber,
                        "decode the first context-negotiation component of an EmbeddedPDV"
                    );

                if (contextNegotiationComponents[1].tagNumber != 1u)
                    throw new ASN1TagNumberException
                    (
                        [ 1u ],
                        contextNegotiationComponents[1].tagNumber,
                        "decode the second context-negotiation component of an EmbeddedPDV"
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
                throw new ASN1TagNumberException
                (
                    [ 0u, 1u, 2u, 3u, 4u, 5u ],
                    identificationChoice.tagNumber,
                    "decode an EmbeddedPDV identification"
                );
        }

        EmbeddedPDV pdv = EmbeddedPDV();
        pdv.identification = identification;
        pdv.dataValue = components[1].octetString;
        return pdv;
    }

    /**
        Encodes an $(MONO EmbeddedPDV), which is a constructed data type, defined in
            the $(LINK https://www.itu.int, International Telecommunications Union)'s
            $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines $(MONO EmbeddedPDV) as:

        $(PRE
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

        This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
        choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.

        Throws:
        $(UL
            $(LI $(D ASN1ValueException) if encoded ObjectDescriptor contains
                invalid characters)
        )
    */
    override public @property @system
    void embeddedPresentationDataValue(in EmbeddedPDV value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        scope(success) this.construction = ASN1Construction.constructed;
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

            identificationChoice.construction = ASN1Construction.constructed;
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

            identificationChoice.construction = ASN1Construction.constructed;
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
            0x0Bu, 0x0Au, // EmbeddedPDV, Length 11
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
        $(UL
            $(LI $(D UTF8Exception)
                if the encoded value does not decode to UTF-8)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    string unicodeTransformationFormat8String() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            return cast(string) this.value;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a UTF8String");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!string appendy = appender!string();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed UTF8String");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed UTF8String");

                appendy.put(substring.utf8String);
            }
            return appendy.data;
        }
    }

    /// Encodes a UTF-8 string to bytes.
    override public @property @system nothrow
    void unicodeTransformationFormat8String(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = cast(ubyte[]) value.dup;
    }

    @system
    unittest
    {
        ubyte[] data = [
            0x2Cu, 0x12u,
                0x0Cu, 0x04u, 'S', 'h', 'i', 'a',
                0x2Cu, 0x04u,
                    0x0Cu, 0x02u, 'L', 'a',
                0x0Cu, 0x04u, 'B', 'T', 'F', 'O'
        ];

        BERElement element = new BERElement(data);
        assert(element.utf8String == "ShiaLaBTFO");
    }

    /**
        Decodes a $(MONO RELATIVE OBJECT IDENTIFIER).

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "constructed")
            $(LI $(D ASN1ValuePaddingException) if a single OID number is encoded with
                "leading zero bytes" ($(D 0x80u)))
            $(LI $(D ASN1ValueOverflowException) if a single OID number is too big to
                decode to a $(D size_t))
            $(LI $(D ASN1TruncationException) if a single OID number is "cut off")
        )

        Standards:
        $(UL
            $(LI $(LINK http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660))
        )
    */
    override public @property @system
    OIDNode[] relativeObjectIdentifier() const
    {
        if (this.construction != ASN1Construction.primitive)
            throw new ASN1ConstructionException
            (this.construction, "decode a RELATIVE OID");

        if (this.value.length == 0u) return [];
        foreach (immutable octet; this.value)
        {
            if (octet == 0x80u)
                throw new ASN1ValuePaddingException
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
            throw new ASN1TruncationException
            (size_t.max, this.value.length, "decode a RELATIVE OID");

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
                throw new ASN1ValueOverflowException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a RELATIVE OID that encoded a number on more than " ~
                    "size_t.sizeof bytes. " ~
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
        Encodes a $(MONO RELATIVE OBJECT IDENTIFIER).

        Standards:
            $(LINK http://www.itu.int/rec/T-REC-X.660-201107-I/en, X.660)
    */
    override public @property @system nothrow
    void relativeObjectIdentifier(in OIDNode[] value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
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
        element.value = [ 0x29u, 0x80u, 0x14u ];
        assertThrown!ASN1ValuePaddingException(element.roid);
        element.value = [ 0x29u, 0x80u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.roid);
        element.value = [ 0x80u, 0x80u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.roid);
        element.value = [ 0x29u, 0x14u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.roid);
        element.value = [ 0x29u, 0x80u ];
        assertThrown!ASN1ValuePaddingException(element.roid);

        // Test for non-terminating components
        element.value = [ 0x29u, 0x81u ];
        assertThrown!ASN1TruncationException(element.roid);
        element.value = [ 0x29u, 0x14u, 0x81u ];
        assertThrown!ASN1TruncationException(element.roid);
    }

    /**
        Decodes a sequence of elements

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "primitive")
            $(LI And all of the exceptions thrown by the constructor)
        )
    */
    override public @property @system
    BERElement[] sequence() const
    {
        if (this.construction != ASN1Construction.constructed)
            throw new ASN1ConstructionException
            (this.construction, "decode a SEQUENCE");

        ubyte[] data = this.value.dup;
        BERElement[] result;
        while (data.length > 0u)
            result ~= new BERElement(data);
        return result;
    }

    /// Encodes a sequence of elements
    override public @property @system
    void sequence(in BERElement[] value)
    {
        scope(success) this.construction = ASN1Construction.constructed;
        ubyte[] result;
        foreach (bv; value)
        {
            result ~= bv.toBytes;
        }
        this.value = result;
    }

    /**
        Decodes a set of elements

        Throws:
        $(UL
            $(LI $(D ASN1ConstructionException) if the element is marked as "primitive")
            $(LI And all of the exceptions thrown by the constructor)
        )
    */
    override public @property @system
    BERElement[] set() const
    {
        if (this.construction != ASN1Construction.constructed)
            throw new ASN1ConstructionException
            (this.construction, "decode a SET");

        ubyte[] data = this.value.dup;
        BERElement[] result;
        while (data.length > 0u)
            result ~= new BERElement(data);
        return result;
    }

    /// Encodes a set of elements
    override public @property @system
    void set(in BERElement[] value)
    {
        scope(success) this.construction = ASN1Construction.constructed;
        ubyte[] result;
        foreach (bv; value)
        {
            result ~= bv.toBytes;
        }
        this.value = result;
    }

    /**
        Decodes a string, where the characters of the string are limited to
        0 - 9 and $(MONO SPACE).

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any character other than 0-9 or space is encoded.)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    string numericString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            foreach (immutable character; this.value)
            {
                if (!canFind(numericStringCharacters, character))
                    throw new ASN1ValueCharactersException
                    ("1234567890 ", character, "NumericString");
            }
            return cast(string) this.value;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a NumericString");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!string appendy = appender!string();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed NumericString");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed NumericString");

                appendy.put(substring.numericString);
            }
            return appendy.data;
        }
    }

    /**
        Encodes a string, where the characters of the string are limited to
        0 - 9 and space.

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any character other than 0-9 or space is supplied.)
        )
    */
    override public @property @system
    void numericString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!canFind(numericStringCharacters, character))
                throw new ASN1ValueCharactersException
                ("1234567890 ", character, "NumericString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a string that will only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period,
        forward slash, colon, equals, and question mark.

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException)
                if any character other than a-z, A-Z,
                0-9, space, apostrophe, parentheses, comma, minus, plus,
                period, forward slash, colon, equals, or question mark are
                encoded)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    string printableString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            foreach (immutable character; this.value)
            {
                if (!canFind(printableStringCharacters, character))
                    throw new ASN1ValueCharactersException
                    (printableStringCharacters, character, "PrintableString");
            }
            return cast(string) this.value;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a PrintableString");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!string appendy = appender!string();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed PrintableString");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed PrintableString");

                appendy.put(substring.printableString);
            }
            return appendy.data;
        }
    }

    /**
        Encodes a string that may only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period,
        forward slash, colon, equals, and question mark.

        Throws:
            $(LI $(D ASN1ValueCharactersException) if any character other than a-z, A-Z,
                0-9, space, apostrophe, parentheses, comma, minus, plus,
                period, forward slash, colon, equals, or question mark are
                supplied)
    */
    override public @property @system
    void printableString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!canFind(printableStringCharacters, character))
                throw new ASN1ValueCharactersException
                (printableStringCharacters, character, "PrintableString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array, where each byte is a T.61 character.

        Throws:
        $(UL
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    ubyte[] teletexString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            return this.value.dup;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a TeletexString");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!(ubyte[]) appendy = appender!(ubyte[])();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed TeletexString");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed TeletexString");

                appendy.put(substring.teletexString);
            }
            return appendy.data;
        }
    }

    /// Literally just sets the value bytes.
    override public @property @safe nothrow
    void teletexString(in ubyte[] value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = value.dup;
    }

    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array, where each byte is a Videotex character.

        Throws:
        $(UL
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    ubyte[] videotexString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            return this.value.dup;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a VideotexString");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!(ubyte[]) appendy = appender!(ubyte[])();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed VideotexString");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed VideotexString");

                appendy.put(substring.videotexString);
            }
            return appendy.data;
        }
    }

    /// Literally just sets the value bytes.
    override public @property @safe nothrow
    void videotexString(in ubyte[] value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        this.value = value.dup;
    }

    /**
        Decodes a string that only contains ASCII characters.

        $(MONO IA5String) differs from ASCII ever so slightly: IA5 is international,
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
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any encoded character is not ASCII)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    string internationalAlphabetNumber5String() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            string ret = cast(string) this.value;
            foreach (immutable character; ret)
            {
                if (!character.isASCII)
                    throw new ASN1ValueCharactersException
                    ("all ASCII characters", character, "IA5String");
            }
            return ret;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a IA5String");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!string appendy = appender!string();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed IA5String");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed IA5String");

                appendy.put(substring.ia5String);
            }
            return appendy.data;
        }
    }

    /**
        Encodes a string that may only contain ASCII characters.

        $(MONO IA5String) differs from ASCII ever so slightly: IA5 is international,
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
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any encoded character is not ASCII)
        )
    */
    override public @property @system
    void internationalAlphabetNumber5String(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!character.isASCII)
                throw new ASN1ValueCharactersException
                ("all ASCII characters", character, "IA5String");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime).
        The value is just the ASCII character representation of the UTC-formatted timestamp.

        An UTC Timestamp looks like:
        $(UL
            $(LI $(MONO 9912312359Z))
            $(LI $(MONO 991231235959+0200))
        )

        If the first digit of the two-digit year is 7, 6, 5, 4, 3, 2, 1, or 0,
        meaning that the date refers to the first 80 years of the century, this
        assumes we are talking about the 21st century and prepend '20' when
        creating the ISO Date String. Otherwise, it assumes we are talking
        about the 20th century, and prepend '19' when creating the string.

        See_Also:
        $(UL
            $(LI $(LINK https://www.obj-sys.com/asn1tutorial/node15.html, UTCTime))
            $(LI $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime))
        )

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any character is not valid in a $(MONO Visiblestring))
            $(LI $(D DateTimeException) if the encoded string cannot be decoded to a DateTime)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    DateTime coordinatedUniversalTime() const
    {
        string value = this.visibleString;
        if ((value.length < 10u) || (value.length > 17u))
            throw new ASN1ValueSizeException(10u, 17u, value.length, "decode a UTCTime");

        /** NOTE:
            .fromISOString() MUST be called from SysTime, not DateTime. There
            is a subtle difference in how .fromISOString() works in both SysTime
            and DateTime: SysTime's accepts the "Z" at the end (indicating that
            the time is in GMT).

            If you use DateTime.fromISOString, you will get a DateTimeException
            whose cryptic message reads "Invalid ISO String: " followed,
            strangely, by only the last six characters of the string.
        */
        value = (((value[0] <= '7') ? "20" : "19") ~ value);
        return cast(DateTime) SysTime.fromISOString(value[0 .. 8] ~ "T" ~ value[8 .. $]);
    }

    /**
        Encodes a $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime).
        The value is just the ASCII character representation of the UTC-formatted timestamp.

        An UTC Timestamp looks like:
        $(UL
            $(LI $(MONO 9912312359Z))
            $(LI $(MONO 991231235959+0200))
        )

        See_Also:
            $(LINK https://www.obj-sys.com/asn1tutorial/node15.html, UTCTime)
    */
    override public @property @system nothrow
    void coordinatedUniversalTime(in DateTime value)
    out
    {
        assert(this.value.length > 10u);
    }
    body
    {
        scope(success) this.construction = ASN1Construction.primitive;
        import std.string : replace;
        immutable SysTime st = SysTime(value, UTC());
        this.value = cast(ubyte[]) ((st.toUTC()).toISOString()[2 .. $].replace("T", ""));
    }

    @system
    unittest
    {
        ubyte[] data = [
            0x37u, 0x19u,
                0x17u, 0x02u, '1', '8',
                0x37u, 0x80u, 0x17u, 0x02u, '0', '1', 0x00u, 0x00u, // Just an extra test for funsies
                0x17u, 0x02u, '0', '7',
                0x17u, 0x07u, '0', '0', '0', '0', '0', '0', 'Z'
        ];

        BERElement element = new BERElement(data);
        assert(element.utcTime == DateTime(2018, 1, 7, 0, 0, 0));
    }

    /**
        Decodes a $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime).
        The value is just the ASCII character representation of
        the $(LINK https://www.iso.org/iso-8601-date-and-time-format.html, ISO 8601)-formatted timestamp.

        An ISO-8601 Timestamp looks like:
        $(UL
            $(LI $(MONO 19851106210627.3))
            $(LI $(MONO 19851106210627.3Z))
            $(LI $(MONO 19851106210627.3-0500))
        )

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any character is not valid in a $(MONO Visiblestring))
            $(LI $(D DateTimeException) if the encoded string cannot be decoded to a DateTime)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )

        Standards:
        $(UL
            $(LI $(LINK https://www.iso.org/iso-8601-date-and-time-format.html, ISO 8601))
        )
    */
    override public @property @system
    DateTime generalizedTime() const
    {
        string value = this.visibleString.replace(",", ".");
        if (value.length < 10u)
            throw new ASN1ValueSizeException(10u, size_t.max, value.length, "decode a GeneralizedTime");

        /** NOTE:
            .fromISOString() MUST be called from SysTime, not DateTime. There
            is a subtle difference in how .fromISOString() works in both SysTime
            and DateTime: SysTime's accepts the "Z" at the end (indicating that
            the time is in GMT).

            If you use DateTime.fromISOString, you will get a DateTimeException
            whose cryptic message reads "Invalid ISO String: " followed,
            strangely, by only the last six characters of the string.
        */
        return cast(DateTime) SysTime.fromISOString(value[0 .. 8] ~ "T" ~ value[8 .. $]);
    }

    /**
        Encodes a $(LINK https://dlang.org/phobos/std_datetime_date.html#.DateTime, DateTime).

        The value is just the ASCII character representation of
        the $(LINK https://www.iso.org/iso-8601-date-and-time-format.html,
        ISO 8601)-formatted timestamp.

        An ISO-8601 Timestamp looks like:
        $(UL
            $(LI $(MONO 19851106210627.3))
            $(LI $(MONO 19851106210627.3Z))
            $(LI $(MONO 19851106210627.3-0500))
        )

        Standards:
        $(UL
            $(LI $(LINK https://www.iso.org/iso-8601-date-and-time-format.html, ISO 8601))
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
        scope(success) this.construction = ASN1Construction.primitive;
        import std.string : replace;
        immutable SysTime st = SysTime(value, UTC());
        this.value = cast(ubyte[]) ((st.toUTC()).toISOString().replace("T", ""));
    }

    /**
        Decodes an ASCII string that contains only characters between and
        including $(D 0x20) and $(D 0x75). Deprecated, according to page 182 of the
        Dubuisson book.

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any non-graphical character (including space) is encoded)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 175-178.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    string graphicString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            string ret = cast(string) this.value;
            foreach (immutable character; ret)
            {
                if (!character.isGraphical && character != ' ')
                    throw new ASN1ValueCharactersException
                    ("all characters within the range 0x20 to 0x7E", character, "GraphicString");
            }
            return ret;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a GraphicString");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!string appendy = appender!string();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed GraphicString");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed GraphicString");

                appendy.put(substring.graphicString);
            }
            return appendy.data;
        }
    }

    /**
        Encodes an ASCII string that may contain only characters between and
        including $(D 0x20) and $(D 0x75). Deprecated, according to page 182
        of the Dubuisson book.

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any non-graphical character (including space) is supplied)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, pp. 175-178.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    void graphicString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueCharactersException
                ("all characters within the range 0x20 to 0x7E", character, "GraphicString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a string that only contains characters between and including
        $(D 0x20) and $(D 0x7E). (Honestly, I don't know how this differs from
        $(MONO GraphicalString).)

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException)
                if any non-graphical character (including space) is encoded)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    string visibleString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            string ret = cast(string) this.value;
            foreach (immutable character; ret)
            {
                if (!character.isGraphical && character != ' ')
                    throw new ASN1ValueCharactersException
                    ("all characters within the range 0x20 to 0x7E", character, "VisibleString");
            }
            return ret;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a VisibleString");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!string appendy = appender!string();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed VisibleString");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed VisibleString");

                appendy.put(substring.visibleString);
            }
            return appendy.data;
        }
    }

    /**
        Encodes a string that only contains characters between and including
        $(D 0x20) and $(D 0x7E). (Honestly, I don't know how this differs from
        $(MONO GraphicalString).)

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException)
                if any non-graphical character (including space) is supplied.)
        )
    */
    override public @property @system
    void visibleString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new ASN1ValueCharactersException
                ("all characters within the range 0x20 to 0x7E", character, "VisibleString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a string containing only ASCII characters. Deprecated, according
        to page 182 of the Dubuisson book.

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any encoded character is not ASCII)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, p. 182.)
            $(LI $(LINK https://en.wikipedia.org/wiki/ISO/IEC_2022, The Wikipedia Page on ISO 2022))
            $(LI $(LINK https://www.iso.org/standard/22747.html, ISO 2022))
        )
    */
    override public @property @system
    string generalString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            string ret = cast(string) this.value;
            foreach (immutable character; ret)
            {
                if (!character.isASCII)
                    throw new ASN1ValueCharactersException
                    ("all ASCII characters", character, "GeneralString");
            }
            return ret;
        }
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a GeneralString");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!string appendy = appender!string();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed GeneralString");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed GeneralString");

                appendy.put(substring.generalString);
            }
            return appendy.data;
        }
    }

    /**
        Encodes a string containing only ASCII characters. Deprecated,
        according to page 182 of the Dubuisson book.

        Throws:
        $(UL
            $(LI $(D ASN1ValueCharactersException) if any encoded character is not ASCII)
        )

        Citations:
        $(UL
            $(LI Dubuisson, Olivier. “Basic Encoding Rules (BER).”
                $(I ASN.1: Communication between Heterogeneous Systems),
                Morgan Kaufmann, 2001, p. 182.)
        )
    */
    override public @property @system
    void generalString(in string value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
        foreach (immutable character; value)
        {
            if (!character.isASCII)
                throw new ASN1ValueCharactersException
                ("all ASCII characters", character, "GeneralString");
        }
        this.value = cast(ubyte[]) value.dup;
    }

    /**
        Decodes a $(MONO dstring) of UTF-32 characters.

        Throws:
        $(UL
            $(LI $(D ASN1ValueException)
                if the encoded bytes is not evenly divisible by four)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    dstring universalString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            if (this.value.length == 0u) return ""d;
            if (this.value.length % 4u)
                throw new ASN1ValueException
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
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a UniversalString");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!dstring appendy = appender!dstring();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed UniversalString");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed UniversalString");

                appendy.put(substring.universalString);
            }
            return appendy.data;
        }
    }

    /// Encodes a $(MONO dstring) of UTF-32 characters.
    override public @property @system
    void universalString(in dstring value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
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
        Decodes a $(MONO CharacterString), which is a constructed data type, defined
        in the $(LINK https://www.itu.int, International Telecommunications Union)'s
            $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines $(MONO CharacterString) as:

        $(PRE
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

        This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
        choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.

        Returns: an instance of $(D types.universal.characterstring.CharacterString).

        Throws:
        $(UL
            $(LI $(D ASN1ValueException) if encoded $(MONO CharacterString) has too few or too many
                elements, or if $(MONO syntaxes) or $(MONO context-negotiation) element has
                too few or too many elements)
            $(LI $(D ASN1ValueSizeException) if encoded $(MONO INTEGER) is too large to decode)
            $(LI $(D ASN1RecursionException) if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException) if any nested primitives do not have the
                correct tag class)
            $(LI $(D ASN1ConstructionException) if any element has the wrong construction)
            $(LI $(D ASN1TagNumberException) if any nested primitives do not have the
                correct tag number)
        )
    */
    override public @property @system
    CharacterString characterString() const
    {
        if (this.construction != ASN1Construction.constructed)
            throw new ASN1ConstructionException
            (this.construction, "decode a CharacterString");

        const BERElement[] components = this.sequence;
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length != 2u)
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode " ~
                "a CharacterString that contained too many or too few elements. " ~
                "A CharacterString should have only two elements: " ~
                "an identification CHOICE, and a data-value OCTET STRING, " ~
                "in that order. " ~
                notWhatYouMeantText ~ forMoreInformationText ~
                debugInformationText ~ reportBugsText
            );

        if (components[0].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            (
                [ ASN1TagClass.contextSpecific ],
                components[0].tagClass,
                "decode the first component of a CharacterString"
            );

        if (components[1].tagClass != ASN1TagClass.contextSpecific)
            throw new ASN1TagClassException
            (
                [ ASN1TagClass.contextSpecific ],
                components[1].tagClass,
                "decode the second component of a CharacterString"
            );

        /* NOTE:
            See page 224 of Dubuisson, item 11:
            It sounds like, even if you have an ABSENT constraint applied,
            all automatically-tagged items still have the same numbers as
            though the constrained component were PRESENT.
        */
        if (components[0].tagNumber != 0u)
            throw new ASN1TagNumberException
            ([ 0u ], components[0].tagNumber, "decode the first component of a CharacterString");

        if (components[1].tagNumber != 2u)
            throw new ASN1TagNumberException
            ([ 2u ], components[1].tagNumber, "decode the second component of a CharacterString");

        ubyte[] bytes = components[0].value.dup;
        const BERElement identificationChoice = new BERElement(bytes);
        switch (identificationChoice.tagNumber)
        {
            case (0u): // syntaxes
            {
                if (identificationChoice.construction != ASN1Construction.constructed)
                    throw new ASN1ConstructionException
                    (identificationChoice.construction, "decode the syntaxes component of a CharacterString");

                const BERElement[] syntaxesComponents = identificationChoice.sequence;

                if (syntaxesComponents.length != 2u)
                    throw new ASN1ValueException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a CharacterString whose syntaxes component " ~
                        "contained an invalid number of elements. The " ~
                        "syntaxes component should contain abstract and transfer " ~
                        "syntax OBJECT IDENTIFIERS, in that order. " ~
                        notWhatYouMeantText ~ forMoreInformationText ~
                        debugInformationText ~ reportBugsText
                    );

                // Class Validation
                if (syntaxesComponents[0].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        syntaxesComponents[0].tagClass,
                        "decode the first syntaxes component of a CharacterString"
                    );

                if (syntaxesComponents[1].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        syntaxesComponents[1].tagClass,
                        "decode the second syntaxes component of a CharacterString"
                    );

                // Construction Validation
                if (syntaxesComponents[0].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (syntaxesComponents[0].construction, "decode the first syntaxes component of a CharacterString");

                if (syntaxesComponents[1].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (syntaxesComponents[1].construction, "decode the second syntaxes component of a CharacterString");

                // Number Validation
                if (syntaxesComponents[0].tagNumber != 0u)
                    throw new ASN1TagNumberException
                    (
                        [ 0u ],
                        syntaxesComponents[0].tagNumber,
                        "decode the first syntaxes component of a CharacterString"
                    );

                if (syntaxesComponents[1].tagNumber != 1u)
                    throw new ASN1TagNumberException
                    (
                        [ 1u ],
                        syntaxesComponents[1].tagNumber,
                        "decode the second syntaxes component of a CharacterString"
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
                if (identificationChoice.construction != ASN1Construction.constructed)
                    throw new ASN1ConstructionException
                    (identificationChoice.construction, "decode the context-negotiation component of a CharacterString");

                const BERElement[] contextNegotiationComponents = identificationChoice.sequence;

                if (contextNegotiationComponents.length != 2u)
                    throw new ASN1ValueException
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

                // Class Validation
                if (contextNegotiationComponents[0].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        contextNegotiationComponents[0].tagClass,
                        "decode the first context-negotiation component of a CharacterString"
                    );

                if (contextNegotiationComponents[1].tagClass != ASN1TagClass.contextSpecific)
                    throw new ASN1TagClassException
                    (
                        [ ASN1TagClass.contextSpecific ],
                        contextNegotiationComponents[1].tagClass,
                        "decode the second context-negotiation component of a CharacterString"
                    );

                // Construction Validation
                if (contextNegotiationComponents[0].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (
                        contextNegotiationComponents[0].construction,
                        "decode the first context-negotiation component of a CharacterString"
                    );

                if (contextNegotiationComponents[1].construction != ASN1Construction.primitive)
                    throw new ASN1ConstructionException
                    (
                        contextNegotiationComponents[1].construction,
                        "decode the second context-negotiation component of a CharacterString"
                    );

                // Number Validation
                if (contextNegotiationComponents[0].tagNumber != 0u)
                    throw new ASN1TagNumberException
                    (
                        [ 0u ],
                        contextNegotiationComponents[0].tagNumber,
                        "decode the first context-negotiation component of a CharacterString"
                    );

                if (contextNegotiationComponents[1].tagNumber != 1u)
                    throw new ASN1TagNumberException
                    (
                        [ 1u ],
                        contextNegotiationComponents[1].tagNumber,
                        "decode the second context-negotiation component of a CharacterString"
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
                throw new ASN1TagNumberException
                (
                    [ 0u, 1u, 2u, 3u, 4u, 5u ],
                    identificationChoice.tagNumber,
                    "decode a CharacterString identification"
                );
        }

        CharacterString cs = CharacterString();
        cs.identification = identification;
        cs.stringValue = components[1].octetString;
        return cs;
    }

    /**
        Encodes a $(MONO CharacterString), which is a constructed data type, defined
        in the $(LINK https://www.itu.int, International Telecommunications Union)'s
            $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines $(MONO CharacterString) as:

        $(PRE
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

        This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
        choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.
    */
    override public @property @system
    void characterString(in CharacterString value)
    out
    {
        assert(this.value.length > 0u);
    }
    body
    {
        scope(success) this.construction = ASN1Construction.constructed;
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

            identificationChoice.construction = ASN1Construction.constructed;
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

            identificationChoice.construction = ASN1Construction.constructed;
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
        Decodes a $(MONO wstring) of UTF-16 characters.

        Throws:
        $(UL
            $(LI $(D ASN1ValueException)
                if the encoded bytes is not evenly divisible by two)
            $(LI $(D ASN1RecursionException)
                if using constructed form and the element
                is constructed of too many nested constructed elements)
            $(LI $(D ASN1TagClassException)
                if any nested primitives do not share the
                same tag class as their outer constructed element)
            $(LI $(D ASN1TagNumberException)
                if any nested primitives do not share the
                same tag number as their outer constructed element)
        )
    */
    override public @property @system
    wstring basicMultilingualPlaneString() const
    {
        if (this.construction == ASN1Construction.primitive)
        {
            if (this.value.length == 0u) return ""w;
            if (this.value.length % 2u)
                throw new ASN1ValueException
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
        else
        {
            if (this.valueRecursionCount++ == this.nestingRecursionLimit)
                throw new ASN1RecursionException(this.nestingRecursionLimit, "parse a BMPString");
            scope(exit) this.valueRecursionCount--; // So exceptions do not leave residual recursion.

            Appender!wstring appendy = appender!wstring();
            BERElement[] substrings = this.sequence;
            foreach (substring; substrings)
            {
                if (substring.tagClass != this.tagClass)
                    throw new ASN1TagClassException
                    ([ this.tagClass ], substring.tagClass, "decode a substring of a constructed BMPString");

                if (substring.tagNumber != this.tagNumber)
                    throw new ASN1TagNumberException
                    ([ this.tagNumber ], substring.tagNumber, "decode a substring of a constructed BMPString");

                appendy.put(substring.universalString);
            }
            return appendy.data;
        }
    }

    /// Encodes a $(MONO wstring) of UTF-16 characters.
    override public @property @system
    void basicMultilingualPlaneString(in wstring value)
    {
        scope(success) this.construction = ASN1Construction.primitive;
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

    /// Creates an $(MONO END OF CONTENT)
    public @safe @nogc nothrow
    this()
    {
        this.tagNumber = 0u;
        this.value = [];
    }

    /**
        Creates a $(D BERElement) from the supplied bytes, inferring that the first
        byte is the type tag. The supplied $(D ubyte[]) array is "chomped" by
        reference, so the original array will grow shorter as $(D BERElement)s are
        generated.

        Throws:
            All of the same exceptions as $(D fromBytes())

        Examples:
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
        Creates a $(D BERElement) from the supplied bytes, inferring that the first
        byte is the type tag. The supplied $(D ubyte[]) array is read, starting
        from the index specified by $(D bytesRead), and increments
        $(D bytesRead) by the number of bytes read.

        Throws:
            All of the same exceptions as $(D fromBytes())

        Examples:
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

    /**
        Returns: the number of bytes read

        Throws:
        $(UL
            $(LI $(D ASN1TagPaddingException) if the tag number is "padded" with
                "leading zero bytes" ($(D 0x80u)))
            $(LI $(D ASN1TagOverflowException) if the tag number is too large to
                fit into a $(D size_t))
            $(LI $(D ASN1LengthUndefinedException) if the reserved length byte of
                $(D 0xFF) is encountered)
            $(LI $(D ASN1LengthOverflowException) if the length is too large to fit
                into a $(D size_t))
            $(LI $(D ASN1TruncationException) if the tag, length, or value appear to
                be truncated)
            $(LI $(D ASN1ConstructionException) if the length is indefinite, but the
                element is marked as being encoded primitively)
            $(LI $(D ASN1RecursionException) if, when trying to determine the end of
                an indefinite-length encoded element, the parser has to recurse
                too deep)
        )
    */
    public
    size_t fromBytes (in ubyte[] bytes)
    {
        if (bytes.length < 2u)
            throw new ASN1TruncationException
            (
                2u,
                bytes.length,
                "decode the tag of a Basic Encoding Rules (BER) encoded element"
            );

        // Index of what we are currently parsing.
        size_t cursor = 0u;

        switch (bytes[cursor] & 0b11000000u)
        {
            case (0b00000000u): this.tagClass = ASN1TagClass.universal; break;
            case (0b01000000u): this.tagClass = ASN1TagClass.application; break;
            case (0b10000000u): this.tagClass = ASN1TagClass.contextSpecific; break;
            case (0b11000000u): this.tagClass = ASN1TagClass.privatelyDefined; break;
            default: assert(0, "Impossible tag class appeared!");
        }

        this.construction = ((bytes[cursor] & 0b00100000u) ?
            ASN1Construction.constructed : ASN1Construction.primitive);

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
            if (bytes[cursor] == 0b10000000u)
                throw new ASN1TagPaddingException
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
            {
                if (limit == bytes.length-1)
                {
                    throw new ASN1TruncationException
                    (size_t.max, bytes.length, "decode an ASN.1 tag number");
                }
                else
                {
                    throw new ASN1TagOverflowException
                    (
                        "This exception was thrown because you attempted to decode " ~
                        "a Basic Encoding Rules (BER) encoded element that encoded " ~
                        "a tag number that was either too large to decode or " ~
                        "terminated prematurely."
                    );
                }
            }

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
                    throw new ASN1LengthUndefinedException();

                // Definite Long, if it has made it this far

                if (numberOfLengthOctets > size_t.sizeof)
                    throw new ASN1LengthOverflowException();

                if (cursor + numberOfLengthOctets >= bytes.length)
                    throw new ASN1TruncationException
                    (
                        numberOfLengthOctets,
                        ((bytes.length - 1) - cursor), // FIXME: You can increment the cursor before this.
                        "decode the length of a Basic Encoding Rules (BER) encoded element"
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

                if ((cursor + length) < cursor) // This catches an overflow.
                    throw new ASN1LengthException // REVIEW: Should this be a different exception?
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
                    throw new ASN1TruncationException
                    (
                        length,
                        (bytes.length - cursor),
                        "decode the value of a Basic Encoding Rules (BER) encoded element"
                    );

                this.value = bytes[cursor .. cursor+length].dup;
                return (cursor + length);
            }
            else // Indefinite
            {
                if (this.construction != ASN1Construction.constructed)
                    throw new ASN1ConstructionException
                    (this.construction, "decode an indefinite-length element");

                if (++(this.lengthRecursionCount) > this.nestingRecursionLimit)
                {
                    this.lengthRecursionCount = 0u;
                    throw new ASN1RecursionException
                    (
                        this.nestingRecursionLimit,
                        "decode a Basic Encoding Rules (BER) encoded element " ~
                        "whose value was encoded with indefinite length form " ~
                        "and constructed recursively from deeply nested elements"
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
                }

                if (sentinel == bytes.length && (bytes[sentinel-1] != 0x00u || bytes[sentinel-2] != 0x00u))
                    throw new ASN1TruncationException
                    (
                        length,
                        (length + 2u),
                        "find the END OF CONTENT octets (two consecutive null " ~
                        "bytes) of an indefinite-length encoded " ~
                        "Basic Encoding Rules (BER) element"
                    );

                this.lengthRecursionCount--;
                this.value = bytes[startOfValue .. sentinel-2u].dup;
                return (sentinel);
            }
        }
        else // Definite Short
        {
            ubyte length = (bytes[cursor++] & 0x7Fu);

            if ((cursor + length) > bytes.length)
                throw new ASN1TruncationException
                (
                    length,
                    ((bytes.length - 1) - cursor),
                    "decode the value of a Basic Encoding Rules (BER) encoded element"
                );

            this.value = bytes[cursor .. cursor+length].dup;
            return (cursor + length);
        }
    }

    /**
        This differs from $(D this.value) in that
        $(D this.value) only returns the value octets, whereas
        $(D this.toBytes) returns the type tag, length tag / octets,
        and the value octets, all concatenated.

        This is the exact same as $(D this.opCast!(ubyte[])()).

        Returns: type tag, length tag, and value, all concatenated as a $(D ubyte) array.
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
        This differs from $(D this.value) in that
        $(D this.value) only returns the value octets, whereas
        $(D this.toBytes) returns the type tag, length tag / octets,
        and the value octets, all concatenated.

        This is the exact same as $(D this.toBytes()).

        Returns: type tag, length tag, and value, all concatenated as a $(D ubyte) array.
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
        0x28u, 0x09u, 0x02u, 0x01u, 0x1Bu, 0x81, 0x04u, 0x01u,
        0x02u, 0x03u, 0x04u ];
    immutable ubyte[] dataReal = [ 0x09u, 0x03u, 0x80u, 0xFBu, 0x05u ]; // 0.15625 (From StackOverflow question)
    immutable ubyte[] dataEnum = [ 0x0Au, 0x01u, 0x3Fu ];
    immutable ubyte[] dataEmbeddedPDV = [
        0x2Bu, 0x0Bu, 0x80u, 0x03u, 0x82u, 0x01u, 0x1Bu, 0x82u,
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
        0x3Du, 0x0Cu, 0x80u, 0x03u, 0x82u, 0x01u, 0x3Fu, 0x82u,
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
    assert(result[9].realNumber!float == 0.15625);
    assert(result[9].realNumber!double == 0.15625);
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
    assert(result[9].realNumber!float == 0.15625);
    assert(result[9].realNumber!double == 0.15625);
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

    BERElement[] results;
    size_t i = 0u;
    while (i < data.length) results ~= new BERElement(i, data);
    assert(results.length == 3);
    foreach (result; results)
    {
        assert(result.length == 216u);
        assert(result.utf8String[0 .. 16] == "AMREN BORTHERS!\n");
    }

    results = [];
    while (data.length > 0) results ~= new BERElement(data);
    assert(results.length == 3);
    foreach (result; results)
    {
        assert(result.length == 216u);
        assert(result.utf8String[0 .. 16] == "AMREN BORTHERS!\n");
    }
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
        0x24u, 0x80u,
            0x04u, 0x04u, 0x00u, 0x00u, 0x00u, 0x00u, // These should not indicate the end.
            0x00u, 0x00u ]; // These should.
    assert((new BERElement(data)).value == [ 0x04u, 0x04u, 0x00u, 0x00u, 0x00u, 0x00u ]);
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
    test[1] = 0b10000010u; // Length is encoded on next two octets
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
        assertThrown!ASN1TruncationException(new BERElement(data));
    }

    size_t index;
    for (ubyte i = 0x00u; i < ubyte.max; i++)
    {
        immutable ubyte[] data = [i];
        assertThrown!ASN1TruncationException(new BERElement(index, data));
    }
}

@system
unittest
{
    BERElement el = new BERElement();
    el.realNumber!float = 1.0;
    assert(approxEqual(el.realNumber!float, 1.0));
    assert(approxEqual(el.realNumber!double, 1.0));
    el.realNumber!double = 1.0;
    assert(approxEqual(el.realNumber!float, 1.0));
    assert(approxEqual(el.realNumber!double, 1.0));
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
    assertThrown!ASN1TruncationException(new BERElement(test));
}

// Test that a misleading definite-long length byte does not throw a RangeError.
@system
unittest
{
    ubyte[] invalid = [ 0b00000000u, 0b10000001u ];
    assertThrown!ASN1TruncationException(new BERElement(invalid));
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
    assertThrown!ASN1TruncationException(new BERElement(big));
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
    assertThrown!ASN1LengthException(new BERElement(big));
}

// Test that a short indefinite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x3F, 0x00u, 0x80, 0x00u ];
    size_t bytesRead = 0u;
    assertThrown!ASN1TruncationException(new BERElement(bytesRead, naughty));
}

// Test that a short indefinite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x3F, 0x00u, 0x80, 0x00u, 0x00u ];
    size_t bytesRead = 0u;
    assertNotThrown!ASN1TruncationException(new BERElement(bytesRead, naughty));
}

// Test that a valueless long-form definite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x00u, 0x82, 0x00u, 0x01u ];
    size_t bytesRead = 0u;
    assertThrown!ASN1TruncationException(new BERElement(bytesRead, naughty));
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