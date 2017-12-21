/**
    Canonical Encoding Rules (CER) is a standard for encoding ASN.1 data.
    CER is often used for cryptgraphically-signed data, such as X.509
    certificates, because CER's defining feature is that there is only one way
    to encode each data type, which means that two encodings of the same data
    could not have different cryptographic signatures. For this reason, CER
    is generally regarded as the most secure encoding standard for ASN.1.
    Like Basic Encoding Rules (BER), Canonical Encoding Rules (CER), and 
    Packed Encoding Rules (PER), Canonical Encoding Rules is a 
    specification created by the 
    $(LINK2 http://www.itu.int/en/pages/default.aspx, 
        International Telecommunications Union),
    and specified in 
    $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

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
module codecs.cer;
public import codec;
public import interfaces : Byteable;
public import types.identification;

///
public alias cerOID = canonicalEncodingRulesObjectIdentifier;
///
public alias cerObjectID = canonicalEncodingRulesObjectIdentifier;
///
public alias cerObjectIdentifier = canonicalEncodingRulesObjectIdentifier;
/** 
    The object identifier assigned to the Canonical Encoding Rules (CER), per the
    $(LINK2 http://www.itu.int/en/pages/default.aspx, 
        International Telecommunications Union)'s,
    $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

    $(I {joint-iso-itu-t asn1(1) ber-derived(2) canonical-encoding(0)} )
*/
public immutable OID canonicalEncodingRulesObjectIdentifier = cast(immutable(OID)) new OID(2, 1, 2, 0);

///
public alias CERElement = CanonicalEncodingRulesElement;
/**
    The unit of encoding and decoding for Canonical Encoding Rules CER.
    
    There are three parts to an encoded CER Value:

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
    CERElement cv = new CERElement();
    cv.tagNumber = 0x02u; // "2" means this is an INTEGER
    cv.integer = 1433; // Now the data is encoded.
    transmit(cast(ubyte[]) cv); // transmit() is a made-up function.
    ---

    And this is what decoding looks like:

    ---
    ubyte[] data = receive(); // receive() is a made-up function.
    CERElement cv2 = new CERElement(data);

    long x;
    if (cv.tagNumber == 0x02u) // it is an INTEGER
    {
        x = cv.integer;
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
class CanonicalEncodingRulesElement : ASN1Element!CERElement, Byteable
{
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

    public ASN1TagClass tagClass;
    public ASN1Construction construction;
    public size_t tagNumber;

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
                "In Canonical Encoding Rules, a BOOLEAN must be encoded on exactly " ~
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
                "that was encoded on a byte that was not 0xFF or 0x00 using the CER " ~
                "codec. Any encoding of a boolean other than 0xFF (true) or 0x00 " ~
                "(false) is restricted by the CER codec. " ~ notWhatYouMeantText ~
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
    void boolean(in bool value)
    {
        this.value = [(value ? 0xFFu : 0x00u)];
    }

    ///
    @safe
    unittest
    {
        CERElement cv = new CERElement();
        cv.value = [ 0xFFu ];
        assert(cv.boolean == true);
        cv.value = [ 0x00u ];
        assert(cv.boolean == false);
        cv.value = [ 0x01u, 0x00u ];
        assertThrown!ASN1ValueSizeException(cv.boolean);
        cv.value = [];
        assertThrown!ASN1ValueSizeException(cv.boolean);
        cv.value = [ 0x01u ];
        assertThrown!ASN1ValueInvalidException(cv.boolean);
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
                "INTEGER that was encoded on 0 bytes. According to the Canonical " ~
                "Encoding Rules (CER), an INTEGER must be encoded on at least " ~
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
            Because the CER INTEGER is stored in two's complement form, you 
            can't just apppend 0x00u to the big end of it until it is as long
            as T in bytes, then cast to T. Instead, you have to first determine
            if the encoded integer is negative or positive. If it is negative,
            then you actually want to append 0xFFu to the big end until it is
            as big as T, so you get the two's complement form of whatever T
            you choose.

            The line immediately below this determines whether the padding byte
            should be 0xFF or 0x00 based on the most significant bit of the 
            most significant byte (which, since CER encodes big-endian, will
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
        CERElement el = new CERElement();

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

    /**
        Decodes an array of $(D bool)s representing a string of bits.

        In Canonical Encoding Rules, the first byte is an unsigned
        integral byte indicating the number of unused bits at the end of
        the BIT STRING. The unused bits must be zeroed.

        Returns: an array of booleans.
        Throws:
            ASN1ValueInvalidException = if the first byte has a value greater
                than seven.
    */
    override public @property @system
    bool[] bitString() const
    in
    {
        // If the blank constructor ever stops producing an EOC, 
        // this method must change.
        CERElement test = new CERElement();
        assert(test.tagNumber == 0x00u);
        assert(test.length == 0u);
    }
    body
    {
        if (this.value.length <= 1000u)
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
                    "In Canonical Encoding Rules, the first byte of the encoded " ~
                    "binary value (after the type and length bytes, of course) " ~ 
                    "is used to indicate how many unused bits there are at the " ~
                    "end of the BIT STRING. Since everything is encoded in bytes " ~
                    "in Canonical Encoding Rules, but a BIT STRING may not " ~
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
        else
        {
            bool[] ret;
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }
            for (size_t p = 0u; p < primitives.length; p++)
            {
                if (primitives[p].length == 0u)
                    throw new ASN1ValueTooSmallException
                    (
                        "This exception was thrown because you attempted to decode a " ~
                        "BIT STRING that was encoded on zero bytes. A BIT STRING " ~
                        "requires at least one byte to encode the length. " 
                        ~ notWhatYouMeantText ~ forMoreInformationText ~ 
                        debugInformationText ~ reportBugsText
                    );

                if (primitives[p].value[0] > 0x07u)
                    throw new ASN1ValueInvalidException
                    (
                        "In Canonical Encoding Rules, the first byte of the encoded " ~
                        "binary value (after the type and length bytes, of course) " ~ 
                        "is used to indicate how many unused bits there are at the " ~
                        "end of the BIT STRING. Since everything is encoded in bytes " ~
                        "in Canonical Encoding Rules, but a BIT STRING may not " ~
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
                
                bool[] pret;
                for (size_t i = 1; i < primitives[p].value.length; i++)
                {
                    pret ~= [
                        (primitives[p].value[i] & 0b1000_0000u ? true : false),
                        (primitives[p].value[i] & 0b0100_0000u ? true : false),
                        (primitives[p].value[i] & 0b0010_0000u ? true : false),
                        (primitives[p].value[i] & 0b0001_0000u ? true : false),
                        (primitives[p].value[i] & 0b0000_1000u ? true : false),
                        (primitives[p].value[i] & 0b0000_0100u ? true : false),
                        (primitives[p].value[i] & 0b0000_0010u ? true : false),
                        (primitives[p].value[i] & 0b0000_0001u ? true : false)
                    ];
                }
                pret.length -= primitives[p].value[0];
                ret ~= pret;
            }
            return ret;
        }
    }

    /**
        Encodes an array of $(D bool)s representing a string of bits.

        In Canonical Encoding Rules, the first byte is an unsigned
        integral byte indicating the number of unused bits at the end of
        the BIT STRING. The unused bits must be zeroed.
    */
    override public @property @system
    void bitString(in bool[] value)
    {
        ubyte[] ub;
        ub.length = ((value.length / 8u) + (value.length % 8u ? 1u : 0u));
        
        // FIXME: Copy this over to the other codecs. This is way better.
        for (size_t i = 0u; i < value.length; i++)
        {
            if (value[i] == false) continue;
            ub[(i/8u)] |= (0b1000_0000u >> (i % 8u));
        }

        if (ub.length <= 999u)
        {
            this.value = [ cast(ubyte) (8u - (value.length % 8u)) ] ~ ub;
            if (this.value[0] == 0x08u) this.value[0] = 0x00u;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+999u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = [ cast(ubyte) 0u ] ~ ub[i .. i+999u];
                primitives ~= x;
                i += 999u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = ([ cast(ubyte) 0u ] ~ ub[i .. $]);
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        bool[] data;
        data.length = 289u;
        for (size_t i = 0u; i < data.length; i++)
        {
            data[i] = cast(bool) (i % 3);
        }
        CERElement el = new CERElement();
        el.bitString = data;
        assert(el.bitString == data);
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            bool[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(bool) (i % 3);
            }
            CERElement el = new CERElement();
            el.bitString = data;
            assert(el.bitString == data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
    }

    /**
        Decodes an OCTET STRING into an unsigned byte array.

        Returns: an unsigned byte array.
    */
    override public @property @system
    ubyte[] octetString() const
    {
        if (this.value.length <= 1000u)
        {
            return this.value.dup;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an OCTET STRING encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length OCTET STRING did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an OCTET STRING, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the OCTET STRING just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(ubyte[]) ret = appender!(ubyte[])();
            foreach (p; primitives)
            {
                ret.put(p.value);
            }            
            return ret.data;
        }
    }

    /**
        Encodes an OCTET STRING from an unsigned byte array.
    */
    override public @property @system
    void octetString(in ubyte[] value)
    in
    {
        // If the blank constructor ever stops producing an EOC, 
        // this method must change.
        CERElement test = new CERElement();
        assert(test.tagNumber == 0x00u);
        assert(test.length == 0u);
    }
    body
    {
        if (value.length <= 1000u)
        {
            this.value = value.dup;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = value[i .. i+1000u].dup;
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = value[i .. $].dup;
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            ubyte[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = (i % 9u);
            }
            CERElement el = new CERElement();
            el.octetString = data;
            assert(el.octetString == data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
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
            if (byteGroup.length > (size_t.sizeof * 2u))
                throw new ASN1ValueTooBigException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an OBJECT IDENTIFIER that encoded a number on more than " ~
                    "size_t*2 bytes (16 on 64-bit, 8 on 32-bit). " ~
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

        return new OID(nodes); // FIXME to not require immutable
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
        CERElement element = new CERElement();

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
        CERElement element = new CERElement();

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
        if (this.value.length <= 1000u)
        {        
            foreach (immutable character; this.value)
            {
                if ((!character.isGraphical) && (character != ' '))
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
            return cast(string) this.value;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an ObjectDescriptor encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length ObjectDescriptor did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an ObjectDescriptor, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the ObjectDescriptor just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(string) ret = appender!(string)();
            foreach (p; primitives)
            {
                foreach (immutable character; p.value)
                {
                    if ((!character.isGraphical) && (character != ' '))
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
                ret.put(cast(string) p.value);
            }
            return ret.data;
        }
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
        
        if (value.length <= 1000u)
        {
            this.value = cast(ubyte[]) value;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = cast(ubyte[]) value[i .. i+1000u];
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = cast(ubyte[]) value[i .. $];
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            char[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = ((i % 0x20u) + 0x41u);
            }
            CERElement el = new CERElement();
            el.objectDescriptor = cast(string) data;
            assert(el.objectDescriptor == cast(string) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
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
    deprecated override public @property @system
    External external() const
    {
        const CERElement[] components = this.sequence;
        External ext = External();
        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();

        if (components.length < 2u || components.length > 3u)
            throw new ASN1ValueSizeException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EXTERNAL that contained too many or too few elements. " ~
                "An EXTERNAL should have either two and three elements: " ~
                "a direct-reference (syntax), an optional " ~
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
                    "class. When using Distinguished Encoding Rules, all but the last " ~
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

        if (components[0].tagNumber != ASN1UniversalType.objectIdentifier)
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to decode " ~
                "an EXTERNAL whose first component was not an " ~
                "OBJECT IDENTIFIER. The first component of an EXTERNAL " ~
                "must be an OBJECT IDENTIFIER if it is " ~ 
                "encoded using Distinguished Encoding Rules. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        identification.directReference = components[0].objectIdentifier;
        if (components.length == 3u)
        {
            if (components[1].tagNumber != ASN1UniversalType.objectDescriptor)
                throw new ASN1TagException
                (
                    "This exception was thrown because you attempted to " ~
                    "decode an EXTERNAL whose second element was not an " ~
                    "ObjectDescriptor. This would not be a problem if you " ~
                    "were using Basic Encoding Rules, but Distinguished " ~
                    "Encoding Rules mandates that only the direct-reference " ~
                    "component can be used to identify EXTERNAL data, so " ~
                    "the second component must necessarily be the data-" ~
                    "value-descriptor if the EXTERNAL is composed of three " ~
                    "components. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            if (components[1].construction == ASN1Construction.primitive)
            {
                ext.dataValueDescriptor = components[1].objectDescriptor;
            }
            else
            {
                Appender!string descriptor = appender!string();
                CERElement[] substrings = components[1].sequence;
                foreach (substring; substrings)
                {
                    descriptor.put(substring.objectDescriptor);
                }
                ext.dataValueDescriptor = descriptor.data;
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
                    "Invalid CHOICE."
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
    */
    deprecated override public @property @system
    void external(in External value)
    {
        CERElement[] components = [];
        
        if (!(value.identification.syntax.isNull))
        {
            CERElement directReference = new CERElement();
            directReference.tagNumber = ASN1UniversalType.objectIdentifier;
            directReference.objectIdentifier = value.identification.directReference;
            components ~= directReference;
        }
        else // it must be the presentationContextID / indirectReference INTEGER
            throw new ASN1ValueInvalidException
            (
                "This exception was thrown because you attempted to encode an " ~
                "EXTERNAL that used something other than syntax as the CHOICE " ~
                "of identification, which is not permitted when using " ~
                "Distinguished Encoding Rules. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        CERElement dataValueDescriptor = new CERElement();
        dataValueDescriptor.tagNumber = ASN1UniversalType.objectDescriptor;
        dataValueDescriptor.objectDescriptor = value.dataValueDescriptor;
        components ~= dataValueDescriptor;

        CERElement dataValue = new CERElement();
        dataValue.tagClass = ASN1TagClass.contextSpecific;
        dataValue.tagNumber = value.encoding;
        dataValue.value = value.dataValue.dup;

        components ~= dataValue;
        this.sequence = components;
    }

    /*
        Since a CER-encoded EXTERNAL can only use the syntax field for
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

        CERElement el = new CERElement();
        assertThrown!ASN1ValueInvalidException(el.external = input);
    }

    /* REVIEW:
        I have not seen it confirmed in the specification that you can use
        base-8 or base-16 for CER-encoded REALs. It seems like that would
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

        For the CER-encoded REAL, a value of 0x40 means "positive infinity,"
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
            Dubuisson, Olivier. “Canonical Encoding Rules (CER).” ASN.1: 
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
                    "a Canonical Encoding Rules-encoded REAL could not fit in " ~
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
                        
                        immutable ubyte exponentLength = this.value[1];

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
                    cast(long) mantissa * // Mantissa MUST be cast to a long
                    2^^scale *
                    (cast(T) base)^^(cast(T) exponent) // base needs to be cast
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
        base-8 or base-16 for CER-encoded REALs. It seems like that would
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

        For the CER-encoded REAL, a value of 0x40 means "positive infinity,"
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
            Dubuisson, Olivier. “Canonical Encoding Rules (CER).” ASN.1: 
            Communication between Heterogeneous Systems, Morgan Kaufmann, 
            2001, pp. 400–402.
    */
    public @property @system
    void realType(T)(in T value)
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
            immutable DoubleRep valueUnion = DoubleRep(value);
            significand = (valueUnion.fraction | 0x0010000000000000u); // Flip bit #53
        }
        static if (is(T == float))
        {
            immutable FloatRep valueUnion = FloatRep(value);
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
        CERElement.realEncodingBase = ASN1RealEncodingBase.base8;
        for (int i = -100; i < 100; i++)
        {
            // Alternating negative and positive floating point numbers exploring extreme values
            immutable float f = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            immutable double d = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            CERElement elf = new CERElement();
            CERElement eld = new CERElement();
            elf.realType!float = f;
            eld.realType!double = d;
            assert(approxEqual(elf.realType!float, f));
            assert(approxEqual(elf.realType!double, f));
            assert(approxEqual(eld.realType!float, d));
            assert(approxEqual(eld.realType!double, d));
        }
        CERElement.realEncodingBase = ASN1RealEncodingBase.base2;
    }

    // Tests of Base-16 Encoding
    @system
    unittest
    {
        CERElement.realEncodingBase = ASN1RealEncodingBase.base16;
        for (int i = -10; i < 10; i++)
        {
            // Alternating negative and positive floating point numbers exploring extreme values
            immutable float f = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            immutable double d = ((i % 2 ? -1 : 1) * 1.23 ^^ i);
            CERElement elf = new CERElement();
            CERElement eld = new CERElement();
            elf.realType!float = f;
            eld.realType!double = d;
            assert(approxEqual(elf.realType!float, f));
            assert(approxEqual(elf.realType!double, f));
            assert(approxEqual(eld.realType!float, d));
            assert(approxEqual(eld.realType!double, d));
        }
        CERElement.realEncodingBase = ASN1RealEncodingBase.base2;
    }

    // Testing Base-10 (Character-Encoded) REALs
    @system
    unittest
    {
        CERElement cv = new CERElement();
        realEncodingBase = ASN1RealEncodingBase.base10;

        // Decimal + trailing zeros are not added if not necessary.
        cv.realType!float = 22.0;
        assert(cast(string) (cv.value[1 .. $]) == "2.200000E+01");
        assert(approxEqual(cv.realType!float, 22.0));
        assert(approxEqual(cv.realType!double, 22.0));
        cv.realType!double = 22.0;
        assert(cast(string) (cv.value[1 .. $]) == "2.200000000000E+01");
        assert(approxEqual(cv.realType!float, 22.0));
        assert(approxEqual(cv.realType!double, 22.0));

        // Decimal + trailing zeros are added if necessary.
        cv.realType!float = 22.123;
        assert(cast(string) (cv.value[1 .. $]) == "2.212300E+01");
        assert(approxEqual(cv.realType!float, 22.123));
        assert(approxEqual(cv.realType!double, 22.123));
        cv.realType!double = 22.123;
        assert(cast(string) (cv.value[1 .. $]) == "2.212300000000E+01");
        assert(approxEqual(cv.realType!float, 22.123));
        assert(approxEqual(cv.realType!double, 22.123));
        
        // Negative numbers are encoded correctly.
        cv.realType!float = -22.123;
        assert(cast(string) (cv.value[1 .. $]) == "-2.212300E+01");
        assert(approxEqual(cv.realType!float, -22.123));
        assert(approxEqual(cv.realType!double, -22.123));
        cv.realType!double = -22.123;
        assert(cast(string) (cv.value[1 .. $]) == "-2.212300000000E+01");
        assert(approxEqual(cv.realType!float, -22.123));
        assert(approxEqual(cv.realType!double, -22.123));

        // Small positive numbers are encoded correctly.
        cv.realType!float = 0.123;     
        assert(cast(string) (cv.value[1 .. $]) == "1.230000E-01");
        assert(approxEqual(cv.realType!float, 0.123));
        assert(approxEqual(cv.realType!double, 0.123));
        cv.realType!double = 0.123;
        assert(cast(string) (cv.value[1 .. $]) == "1.230000000000E-01");
        assert(approxEqual(cv.realType!float, 0.123));
        assert(approxEqual(cv.realType!double, 0.123));

        // Small negative numbers are encoded correctly.
        cv.realType!float = -0.123;
        assert(cast(string) (cv.value[1 .. $]) == "-1.230000E-01");
        assert(approxEqual(cv.realType!float, -0.123));
        assert(approxEqual(cv.realType!double, -0.123));
        cv.realType!double = -0.123;
        assert(cast(string) (cv.value[1 .. $]) == "-1.230000000000E-01");
        assert(approxEqual(cv.realType!float, -0.123));
        assert(approxEqual(cv.realType!double, -0.123));
    }

    /**
        Decodes an integer from an ENUMERATED type. In CER, an ENUMERATED
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
            Because the CER ENUMERATED is stored in two's complement form, you 
            can't just apppend 0x00u to the big end of it until it is as long
            as T in bytes, then cast to T. Instead, you have to first determine
            if the encoded integer is negative or positive. If it is negative,
            then you actually want to append 0xFFu to the big end until it is
            as big as T, so you get the two's complement form of whatever T
            you choose.

            The line immediately below this determines whether the padding byte
            should be 0xFF or 0x00 based on the most significant bit of the 
            most significant byte (which, since CER encodes big-endian, will
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
        Encodes an ENUMERATED type from an integer. In CER, an ENUMERATED
        type is encoded the exact same way that an INTEGER is.
    */
    public @property @system nothrow
    void enumerated(T)(in T value)
    {
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

        In Canonical Encoding Rules, the identification CHOICE cannot be
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
        const CERElement[] components = this.sequence;
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
                "and the data-value OCTET STRING components respectively. " ~
                notWhatYouMeantText ~ forMoreInformationText ~ 
                debugInformationText ~ reportBugsText
            );

        ubyte[] bytes = components[0].value.dup;
        const CERElement identificationChoice = new CERElement(bytes);
        switch (identificationChoice.tagNumber)
        {
            case (0u): // syntaxes
            {
                const CERElement[] syntaxesComponents = identificationChoice.sequence;

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
                    "numbers from 0 to 5. But since you are using Distinguished " ~
                    "Encoding Rules, options 2 and 3 are ruled out by " ~
                    "specification. " ~
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

        In Canonical Encoding Rules, the identification CHOICE cannot be
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
    void embeddedPresentationDataValue(in EmbeddedPDV value)
    {
        CERElement identification = new CERElement();
        identification.tagClass = ASN1TagClass.contextSpecific;
        identification.tagNumber = 0u; // CHOICE is EXPLICIT, even with automatic tagging.

        CERElement identificationChoice = new CERElement();
        identificationChoice.tagClass = ASN1TagClass.contextSpecific;
        if (!(value.identification.syntaxes.isNull))
        {
            CERElement abstractSyntax = new CERElement();
            abstractSyntax.tagClass = ASN1TagClass.contextSpecific;
            abstractSyntax.tagNumber = 0u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            CERElement transferSyntax = new CERElement();
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
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationChoice.tagNumber = 4u;
            identificationChoice.objectIdentifier = value.identification.transferSyntax;
        }
        else
        {
            identificationChoice.tagNumber = 5u;
            identificationChoice.value = [];
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationChoice;

        CERElement dataValue = new CERElement();
        dataValue.tagClass = ASN1TagClass.contextSpecific;
        dataValue.tagNumber = 2u;
        dataValue.octetString = value.dataValue;

        this.sequence = [ identification, dataValue ];
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because CER and CER
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

        CERElement el = new CERElement();
        el.tagNumber = 0x08u;
        el.embeddedPDV = input;
        EmbeddedPDV output = el.embeddedPDV;
        assert(output.identification.fixed == true);
        assert(output.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]);
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because CER and CER
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

        CERElement el = new CERElement();
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
        if (this.value.length <= 1000u)
        {
            return cast(string) this.value;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an OCTET STRING encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length OCTET STRING did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an OCTET STRING, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the OCTET STRING just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(string) ret = appender!(string)();
            foreach (p; primitives)
            {
                ret.put(cast(string) p.value);
            }            
            return ret.data;
        }
    }

    /**
        Encodes a UTF-8 string to bytes. No checks are performed.
    */
    override public @property @system
    void unicodeTransformationFormat8String(in string value)
    {
        if (value.length <= 1000u)
        {
            this.value = cast(ubyte[]) value;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = cast(ubyte[]) value[i .. i+1000u];
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = cast(ubyte[]) value[i .. $];
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            char[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(char) ((i % 0x10) + 0x41);
            }
            CERElement el = new CERElement();
            el.utf8String = cast(string) data;
            assert(el.utf8String == cast(string) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
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
        if (this.value.length == 0u) return [];
        foreach (octet; this.value)
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
            if (byteGroup.length > (size_t.sizeof * 2u))
                throw new ASN1ValueTooBigException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a RELATIVE OID that encoded a number on more than " ~
                    "size_t*2 bytes (16 on 64-bit, 8 on 32-bit). " ~
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
        CERElement element = new CERElement();

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
        CERElement element = new CERElement();

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
        Decodes a sequence of CERElements.

        Returns: an array of CERElements.
        Throws:
            ASN1ValueSizeException = if long definite-length is too big to be
                decoded to an unsigned integral type.
            ASN1ValueTooSmallException = if there are fewer value bytes than
                indicated by the length tag.
    */
    override public @property @system
    CERElement[] sequence() const
    {
        ubyte[] data = this.value.dup;
        CERElement[] result;
        while (data.length > 0u)
            result ~= new CERElement(data);
        return result;
    }

    /**
        Encodes a sequence of CERElements.
    */
    override public @property @system
    void sequence(in CERElement[] value)
    {
        ubyte[] result;
        foreach (cv; value)
        {
            result ~= cv.toBytes;
        }
        this.value = result;
    }

    /**
        Decodes a set of CERElements.

        Returns: an array of CERElements.
        Throws:
            ASN1ValueSizeException = if long definite-length is too big to be
                decoded to an unsigned integral type.
            ASN1ValueTooSmallException = if there are fewer value bytes than
                indicated by the length tag.
    */
    override public @property @system
    CERElement[] set() const
    {
        ubyte[] data = this.value.dup;
        CERElement[] result;
        while (data.length > 0u)
            result ~= new CERElement(data);
        return result;
    }

    /**
        Encodes a set of CERElements.
    */
    override public @property @system
    void set(in CERElement[] value)
    {
        ubyte[] result;
        foreach (cv; value)
        {
            result ~= cv.toBytes;
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
        if (this.value.length <= 1000u)
        {        
            foreach (immutable character; this.value)
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
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an OCTET STRING encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length OCTET STRING did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an OCTET STRING, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the OCTET STRING just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(string) ret = appender!(string)();
            foreach (p; primitives)
            {
                foreach (immutable character; p.value)
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
                ret.put(cast(string) p.value);
            }
            return ret.data;
        }
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
                    character ~ "'. " ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );
        }
        
        if (value.length <= 1000u)
        {
            this.value = cast(ubyte[]) value;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = cast(ubyte[]) value[i .. i+1000u];
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = cast(ubyte[]) value[i .. $];
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            char[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(char) ((i % 0x09) + 0x30);
            }
            CERElement el = new CERElement();
            el.numericString = cast(string) data;
            assert(el.numericString == cast(string) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
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
        if (this.value.length <= 1000u)
        {        
            foreach (immutable character; this.value)
            {
                if (!canFind(printableStringCharacters, character))
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you tried to decode " ~
                        "a PrintableString that contained a character that " ~
                        "is not considered 'printable' by the specification. " ~
                        "The encoding of the encoding of the offending character is '" ~ text(cast(ubyte) character) ~ "'. " ~
                        "The allowed characters are: " ~ printableStringCharacters ~ " " ~
                        notWhatYouMeantText ~ forMoreInformationText ~ 
                        debugInformationText ~ reportBugsText
                    );
            }
            return cast(string) this.value;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an PrintableString encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length PrintableString did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an PrintableString, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the PrintableString just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(string) ret = appender!(string)();
            foreach (p; primitives)
            {
                foreach (immutable character; p.value)
                {
                    if (!canFind(printableStringCharacters, character))
                        throw new ASN1ValueInvalidException
                        (
                            "This exception was thrown because you tried to decode " ~
                            "a PrintableString that contained a character that " ~
                            "is not considered 'printable' by the specification. " ~
                            "The encoding of the encoding of the offending character is '" ~ text(cast(ubyte) character) ~ "'. " ~
                            "The allowed characters are: " ~ printableStringCharacters ~ " " ~
                            notWhatYouMeantText ~ forMoreInformationText ~ 
                            debugInformationText ~ reportBugsText
                        );
                }
                ret.put(cast(string) p.value);
            }
            return ret.data;
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
                    "The encoding of the encoding of the offending character is '" ~ text(cast(ubyte) character) ~ "'. " ~
                    "The allowed characters are: " ~ printableStringCharacters ~ " " ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }
        
        if (value.length <= 1000u)
        {
            this.value = cast(ubyte[]) value;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = cast(ubyte[]) value[i .. i+1000u];
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = cast(ubyte[]) value[i .. $];
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            char[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(char) ((i % 0x10) + 0x41);
            }
            CERElement el = new CERElement();
            el.printableString = cast(string) data;
            assert(el.printableString == cast(string) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
    }
   
    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array, where each byte is a T.61 character.
    */
    override public @property @system
    ubyte[] teletexString() const
    {
        // TODO: Validation.
        if (this.value.length <= 1000u)
        {
            return this.value.dup;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a TeletexString encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length TeletexString did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually a TeletexString, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the TeletexString just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(ubyte[]) ret = appender!(ubyte[])();
            foreach (p; primitives)
            {
                ret.put(p.value);
            }            
            return ret.data;
        }
    }

    /**
        Literally just sets the value bytes.
    */
    override public @property @system
    void teletexString(in ubyte[] value)
    {
        // TODO: Validation.
        if (value.length <= 1000u)
        {
            this.value = value.dup;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = value[i .. i+1000u].dup;
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = value[i .. $].dup;
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            ubyte[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = (i % 9u);
            }
            CERElement el = new CERElement();
            el.teletexString = data;
            assert(el.teletexString == data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
    }

    /**
        Literally just returns the value bytes.

        Returns: an unsigned byte array.
    */
    override public @property @system
    ubyte[] videotexString() const
    {
        // TODO: Validation.
        if (this.value.length <= 1000u)
        {
            return this.value.dup;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a VideotexString encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length VideotexString did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually a VideotexString, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the VideotexString just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(ubyte[]) ret = appender!(ubyte[])();
            foreach (p; primitives)
            {
                ret.put(p.value);
            }            
            return ret.data;
        }
    }

    /**
        Literally just sets the value bytes.
    */
    override public @property @system
    void videotexString(in ubyte[] value)
    {
        // TODO: Validation.
        if (value.length <= 1000u)
        {
            this.value = value.dup;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = value[i .. i+1000u].dup;
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = value[i .. $].dup;
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            ubyte[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = (i % 9u);
            }
            CERElement el = new CERElement();
            el.videotexString = data;
            assert(el.videotexString == data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
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
        if (this.value.length <= 1000u)
        {        
            foreach (immutable character; this.value)
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
            return cast(string) this.value;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an IA5String encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length IA5String did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an IA5String, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the IA5String just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(string) ret = appender!(string)();
            foreach (p; primitives)
            {
                foreach (immutable character; p.value)
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
                ret.put(cast(string) p.value);
            }
            return ret.data;
        }
        return cast(string) this.value;
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
        
        if (value.length <= 1000u)
        {
            this.value = cast(ubyte[]) value;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = cast(ubyte[]) value[i .. i+1000u];
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = cast(ubyte[]) value[i .. $];
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            char[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(char) ((i % 0x40) + 0x30);
            }
            CERElement el = new CERElement();
            el.ia5String = cast(string) data;
            assert(el.ia5String == cast(string) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
    }

    /**
        Decodes a DateTime.
        
        The CER-encoded value is just the ASCII character representation of
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
        immutable string dt = (((this.value[0] <= '7') ? "20" : "19") ~ cast(string) this.value);
        return cast(DateTime) SysTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    /**
        Encodes a DateTime.
        
        The CER-encoded value is just the ASCII character representation of
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
    void coordinatedUniversalTime(in DateTime value)
    {
        import std.string : replace;
        immutable SysTime st = SysTime(value, UTC());
        this.value = cast(ubyte[]) ((st.toUTC()).toISOString()[2 .. $].replace("T", ""));
    }

    /**
        Decodes a DateTime.

        The CER-encoded value is just the ASCII character representation of
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
        immutable string dt = cast(string) this.value;
        return cast(DateTime) SysTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    /**
        Encodes a DateTime.

        The CER-encoded value is just the ASCII character representation of
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
    void generalizedTime(in DateTime value)
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
        if (this.value.length <= 1000u)
        {        
            foreach (immutable character; this.value)
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
            return cast(string) this.value;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "an GraphicString encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length GraphicString did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an GraphicString, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the GraphicString just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(string) ret = appender!(string)();
            foreach (p; primitives)
            {
                foreach (immutable character; p.value)
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
                ret.put(cast(string) p.value);
            }
            return ret.data;
        }
        return cast(string) this.value;
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

        if (value.length <= 1000u)
        {
            this.value = cast(ubyte[]) value;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = cast(ubyte[]) value[i .. i+1000u];
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = cast(ubyte[]) value[i .. $];
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            char[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(char) ((i % 0x40) + 0x20);
            }
            CERElement el = new CERElement();
            el.graphicString = cast(string) data;
            assert(el.graphicString == cast(string) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
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
        if (this.value.length <= 1000u)
        {        
            foreach (immutable character; this.value)
            {
                if (!character.isGraphical && character != ' ')
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you tried to decode " ~
                        "a VisibleString that contained a character that " ~
                        "is not graphical (a character whose ASCII encoding " ~
                        "is outside of the range 0x20 to 0x7E). The encoding of the offending " ~
                        "character is '" ~ text(cast(uint) character) ~ "'. " ~ notWhatYouMeantText ~
                        forMoreInformationText ~ debugInformationText ~ reportBugsText
                    );
            }
            return cast(string) this.value;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a VisibleString encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length VisibleString did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an VisibleString, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the VisibleString just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(string) ret = appender!(string)();
            foreach (p; primitives)
            {
                foreach (immutable character; p.value)
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
                ret.put(cast(string) p.value);
            }
            return ret.data;
        }
        return cast(string) this.value;
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

        if (value.length <= 1000u)
        {
            this.value = cast(ubyte[]) value;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = cast(ubyte[]) value[i .. i+1000u];
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = cast(ubyte[]) value[i .. $];
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            char[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(char) ((i % 0x40) + 0x20);
            }
            CERElement el = new CERElement();
            el.visibleString = cast(string) data;
            assert(el.visibleString == cast(string) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
    }

    /**
        Decodes a string containing only ASCII characters.

        Deprecated, according to page 182 of the Dubuisson book.

        Returns: a string.
        Throws:
            ASN1ValueInvalidException = if any enecoded character is not ASCII.

        Citations:
            Dubuisson, Olivier. “Canonical Encoding Rules (CER).” ASN.1: 
            Communication between Heterogeneous Systems, Morgan Kaufmann, 
            2001, p. 182.
    */
    override public @property @system
    string generalString() const
    {
        if (this.value.length <= 1000u)
        {        
            foreach (immutable character; this.value)
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
            return cast(string) this.value;
        }
        else
        {
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a GeneralString encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length GeneralString did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an GeneralString, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the GeneralString just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(string) ret = appender!(string)();
            foreach (p; primitives)
            {
                foreach (immutable character; p.value)
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
                ret.put(cast(string) p.value);
            }
            return ret.data;
        }
        return cast(string) this.value;
    }

    /**
        Encodes a string containing only ASCII characters.

        Deprecated, according to page 182 of the Dubuisson book.

        Throws:
            ASN1ValueInvalidException = if any enecoded character is not ASCII.

        Citations:
            Dubuisson, Olivier. “Canonical Encoding Rules (CER).” ASN.1: 
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
                    "is not ASCII. The encoding of the offending character is '" ~ text(cast(uint) character) ~ "'. " ~
                    forMoreInformationText ~ debugInformationText ~ reportBugsText
                );
        }

        if (value.length <= 1000u)
        {
            this.value = cast(ubyte[]) value;
        }
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+1000u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                x.value = cast(ubyte[]) value[i .. i+1000u];
                primitives ~= x;
                i += 1000u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            y.value = cast(ubyte[]) value[i .. $];
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            char[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(char) ((i % 0x40) + 0x20);
            }
            CERElement el = new CERElement();
            el.generalString = cast(string) data;
            assert(el.generalString == cast(string) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
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
        if (this.value.length <= 1000u)
        {
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
                while (i < this.value.length-3u)
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
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a UniversalString encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length UniversalString did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an UniversalString, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the UniversalString just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(dstring) ret = appender!(dstring)();
            for (size_t p = 0u; p < primitives.length-1; p++) // Skip the last element, because it is an EOC
            {
                if (primitives[p].value.length % 4u)
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
                    ret.put(cast(dstring) primitives[p].value);
                }
                else version (LittleEndian)
                {
                    dstring segment;
                    size_t i = 0u;
                    while (i < primitives[p].value.length-3)
                    {
                        ubyte[] character;
                        character.length = 4u;
                        character[3] = primitives[p].value[i++];
                        character[2] = primitives[p].value[i++];
                        character[1] = primitives[p].value[i++];
                        character[0] = primitives[p].value[i++];
                        segment ~= (*cast(dchar *) character.ptr);
                    }
                    ret.put(segment);
                }
                else
                {
                    static assert(0, "Could not determine endianness!");
                }
            }
            return ret.data;
        }
    }

    /**
        Encodes a dstring of UTF-32 characters.
    */
    override public @property @system
    void universalString(in dstring value)
    {
        if (value.length <= 250u)
        {
            version (BigEndian)
            {
                this.value = cast(ubyte[]) value;
            }
            else version (LittleEndian)
            {
                foreach (immutable character; value)
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
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+250u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                version (BigEndian)
                {
                    x.value = cast(ubyte[]) value[i .. i+250u];
                }
                else version (LittleEndian)
                {
                    foreach (immutable character; value[i .. i+250u])
                    {
                        ubyte[] charBytes = cast(ubyte[]) *cast(char[4] *) &character;
                        reverse(charBytes);
                        x.value ~= charBytes;
                    }
                }
                else
                {
                    static assert(0, "Could not determine endianness!");
                }
                primitives ~= x;
                i += 250u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            version (BigEndian)
            {
                y.value = cast(ubyte[]) value[i .. $];
            }
            else version (LittleEndian)
            {
                foreach (immutable character; value[i .. $])
                {
                    ubyte[] charBytes = cast(ubyte[]) *cast(char[4] *) &character;
                    reverse(charBytes);
                    y.value ~= charBytes;
                }
            }
            else
            {
                static assert(0, "Could not determine endianness!");
            }
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            dchar[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(dchar) ((i % 0x60u) + 0x20u);
            }
            CERElement el = new CERElement();
            el.universalString = cast(dstring) data;
            assert(el.universalString == cast(dstring) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
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
        const CERElement[] components = this.sequence;
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
                "This exception was thrown because you attempted to decode an " ~
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
        const CERElement identificationChoice = new CERElement(bytes);
        switch (identificationChoice.tagNumber)
        {
            case (0u): // syntaxes
            {
                const CERElement[] syntaxesComponents = identificationChoice.sequence;

                if (syntaxesComponents.length != 2u)
                    throw new ASN1ValueInvalidException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode an CharacterString whose syntaxes component " ~
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
                    "numbers from 0 to 5. But since you are using Distinguished " ~
                    "Encoding Rules, options 2 and 3 are ruled out by " ~
                    "specification. " ~
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
    {
        CERElement identification = new CERElement();
        identification.tagClass = ASN1TagClass.contextSpecific;
        identification.tagNumber = 0u; // CHOICE is EXPLICIT, even with automatic tagging.

        CERElement identificationChoice = new CERElement();
        identificationChoice.tagClass = ASN1TagClass.contextSpecific;
        if (!(value.identification.syntaxes.isNull))
        {
            CERElement abstractSyntax = new CERElement();
            abstractSyntax.tagClass = ASN1TagClass.contextSpecific;
            abstractSyntax.tagNumber = 0u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            CERElement transferSyntax = new CERElement();
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
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationChoice.tagNumber = 4u;
            identificationChoice.objectIdentifier = value.identification.transferSyntax;
        }
        else
        {
            identificationChoice.tagNumber = 5u;
            identificationChoice.value = [];
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationChoice;

        CERElement stringValue = new CERElement();
        stringValue.tagClass = ASN1TagClass.contextSpecific;
        stringValue.tagNumber = 2u;
        stringValue.octetString = value.stringValue;

        this.sequence = [ identification, stringValue ];
    }

    /* NOTE:
        This unit test had to be moved out of ASN1Element because CER and CER
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

        CERElement el = new CERElement();
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
        if (this.value.length <= 1000u)
        {
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
                while (i < this.value.length-1u)
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
            ubyte[] value = this.value.dup;
            CERElement[] primitives;
            while (value.length > 0)
            {
                primitives ~= new CERElement(value);
            }

            if (primitives[$-1].tagNumber != 0x00u && primitives[$-1].length != 0u)
                throw new ASN1ValueInvalidException
                (
                    "This exception was thrown because you attempted to decode " ~
                    "a BMPString encoded via Canonical Encoding Rules (CER) " ~
                    "in constructed form with indefinite length. The encoded " ~
                    "indefinite-length BMPString did not end with an END " ~
                    "OF CONTENT element. This could happen because you attempted " ~
                    "to decode an element that was not actually an BMPString, " ~
                    "or you may be using the wrong codec for the protocol you " ~
                    "are dealing with, or, the BMPString just may be quite large " ~
                    "and you may have not received it entirely yet. " ~
                    notWhatYouMeantText ~ forMoreInformationText ~ 
                    debugInformationText ~ reportBugsText
                );

            Appender!(wstring) ret = appender!(wstring)();
            for (size_t p = 0u; p < primitives.length-1; p++) // Skip the last element, because it is an EOC
            {
                if (primitives[p].value.length % 2u)
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
                    ret.put(cast(wstring) primitives[p].value);
                }
                else version (LittleEndian)
                {
                    dstring segment;
                    size_t i = 0u;
                    while (i < primitives[p].value.length-1u)
                    {
                        ubyte[] character;
                        character.length = 2u;
                        character[1] = primitives[p].value[i++];
                        character[0] = primitives[p].value[i++];
                        segment ~= (*cast(wchar *) character.ptr);
                    }
                    ret.put(segment);
                }
                else
                {
                    static assert(0, "Could not determine endianness!");
                }
            }
            return ret.data;
        }
    }

    /**
        Encodes a wstring of UTF-16 characters.
    */
    override public @property @system
    void basicMultilingualPlaneString(in wstring value)
    {
        if (value.length <= 500u)
        {
            version (BigEndian)
            {
                this.value = cast(ubyte[]) value;
            }
            else version (LittleEndian)
            {
                foreach (immutable character; value)
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
        else
        {
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
            CERElement[] primitives;
            size_t i = 0u;
            while (i+500u < value.length)
            {
                CERElement x = new CERElement();
                x.tagNumber = (this.tagNumber & 0b1101_1111u);
                version (BigEndian)
                {
                    x.value = cast(ubyte[]) value[i .. i+500u];
                }
                else version (LittleEndian)
                {
                    foreach (immutable character; value[i .. i+500u])
                    {
                        ubyte[] charBytes = cast(ubyte[]) *cast(char[2] *) &character;
                        reverse(charBytes);
                        x.value ~= charBytes;
                    }
                }
                else
                {
                    static assert(0, "Could not determine endianness!");
                }
                primitives ~= x;
                i += 500u;
            }
            this.lengthEncodingPreference = LengthEncodingPreference.indefinite;

            CERElement y = new CERElement();
            y.tagNumber = (this.tagNumber & 0b1101_1111u);
            version (BigEndian)
            {
                y.value = cast(ubyte[]) value[i .. $];
            }
            else version (LittleEndian)
            {
                foreach (immutable character; value[i .. $])
                {
                    ubyte[] charBytes = cast(ubyte[]) *cast(char[2] *) &character;
                    reverse(charBytes);
                    y.value ~= charBytes;
                }
            }
            else
            {
                static assert(0, "Could not determine endianness!");
            }
            primitives ~= y;

            CERElement z = new CERElement();
            primitives ~= z;

            this.sequence = primitives;
            this.tagNumber |= 0b0010_0000u;
            this.lengthEncodingPreference = LengthEncodingPreference.definite;
        }
    }

    @system
    unittest
    {
        void test(size_t length)
        {
            wchar[] data;
            data.length = length;
            for (size_t i = 0u; i < data.length; i++)
            {
                data[i] = cast(wchar) ((i % 0x60u) + 0x20u);
            }
            CERElement el = new CERElement();
            el.bmpString = cast(wstring) data;
            assert(el.bmpString == cast(wstring) data);
        }
        test(0u);
        test(1u);
        test(8u);
        test(127u);
        test(128u);
        test(129u);
        test(192u);
        test(999u);
        test(1000u);
        test(1001u);
        test(2017u);
    }

    /**
        Creates an EndOfContent CER Value.
    */
    public @safe @nogc nothrow
    this()
    {
        this.tagNumber = 0u;
        this.value = [];
    }

    /**
        Creates a CERElement from the supplied bytes, inferring that the first
        byte is the type tag. The supplied ubyte[] array is "chomped" by
        reference, so the original array will grow shorter as CERElements are
        generated. 

        Throws:
            ASN1ValueTooSmallException = if the bytes supplied are fewer than
                two (one or zero, in other words), such that no valid CERElement
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
        CERElement[] result;
        while (bytes.length > 0)
            result ~= new CERElement(bytes);

        // Encoding looks like:
        ubyte[] result;
        foreach (cv; bervalues)
        {
            result ~= cast(ubyte[]) cv;
        }
        ---
    */
    public @system
    this(ref ubyte[] bytes)
    {
        size_t bytesRead = this.fromBytes(bytes);
        bytes = bytes[bytesRead .. $];
    }

    /**
        Creates a CERElement from the supplied bytes, inferring that the first
        byte is the type tag. The supplied ubyte[] array is read, starting
        from the index specified by $(D bytesRead), and increments 
        $(D bytesRead) by the number of bytes read.

        Throws:
            ASN1ValueTooSmallException = if the bytes supplied are fewer than
                two (one or zero, in other words), such that no valid CERElement
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
        CERElement[] result;
        size_t i = 0u;
        while (i < bytes.length)
            result ~= new CERElement(i, bytes);

        // Encoding looks like:
        ubyte[] result;
        foreach (cv; bervalues)
        {
            result ~= cast(ubyte[]) cv;
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
            ("CER-encoded value terminated prematurely.");
        
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
                    "a Canonical Encoding Rules (CER) encoded element whose tag " ~
                    "number was encoded in long form in the octets following " ~
                    "the first octet of the type tag, and whose tag number " ~
                    "was encoded with a 'leading zero' byte, 0x80. When " ~
                    "using Canonical Encoding Rules (CER), the tag number must " ~
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
                    "Type tag is too big."
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
                        "A BER-encoded length byte of 0xFF is reserved."
                    );

                // Definite Long, if it has made it this far

                if (numberOfLengthOctets > size_t.sizeof)
                    throw new ASN1ValueTooBigException
                    (
                        "BER-encoded value is too big to decode."
                    );

                if (cursor + numberOfLengthOctets >= bytes.length)
                    throw new ASN1ValueTooSmallException
                    (
                        "Length tag terminated prematurely."
                    );

                if (bytes[++cursor] == 0x00u)
                    throw new ASN1InvalidLengthException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Canonical Encoding Rules (CER) encoded " ~
                        "element whose length was encoded in definite long " ~
                        "form, and encoded on more octets than necessary, " ~
                        "which is prohibited by the specification for " ~
                        "Canonical Encoding Rules (CER). " ~
                        forMoreInformationText ~ debugInformationText ~ reportBugsText
                    );

                ubyte[] lengthNumberOctets;
                lengthNumberOctets.length = size_t.sizeof;
                for (ubyte i = numberOfLengthOctets; i > 0u; i--)
                {
                    lengthNumberOctets[size_t.sizeof-i] = bytes[cursor+numberOfLengthOctets-i];
                }
                version (LittleEndian) reverse(lengthNumberOctets);
                size_t length = *cast(size_t *) lengthNumberOctets.ptr;

                if (length <= 127u)
                    throw new ASN1InvalidLengthException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Canonical Encoding Rules (CER) encoded " ~
                        "element whose length was encoded in definite long " ~
                        "form, and encoded on more octets than necessary, " ~
                        "which is prohibited by the specification for " ~
                        "Canonical Encoding Rules (CER). Specifically, it " ~
                        "was encoded in definite-long form when it was less " ~
                        "than or equal to 127, which could have been encoded " ~
                        "in definite-short form. " ~
                        forMoreInformationText ~ debugInformationText ~ reportBugsText
                    );

                if ((cursor + length) < cursor)
                    throw new ASN1ValueTooBigException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Canonical Encoding Rules (CER) encoded element " ~ 
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
                    ("CER-encoded value terminated prematurely.");

                this.value = bytes[cursor .. cursor+length].dup;
                return (cursor + length);
            }
            else // Indefinite
            {   
                size_t startOfValue = ++cursor;

                if (bytes.length < (cursor + 2u))
                    throw new ASN1ValueTooSmallException
                    (
                        "This exception was thrown because you attempted to " ~
                        "decode a Canonical Encoding Rules (CER) encoded element that " ~
                        "was encoded using indefinite length form, but whose " ~
                        "value octets were too few to contain the necessary " ~
                        "END OF CONTENT octets (two consecutive null bytes). "
                    );

                while (cursor < bytes.length-1)
                {
                    if 
                    (
                        bytes[cursor++] == 0x00u &&
                        bytes[cursor] == 0x00u
                    )
                    break;
                }

                if (bytes[cursor] != 0x00u)
                    throw new ASN1ValueTooSmallException
                    ("No end-of-content word [0x00,0x00] found at the end of indefinite-length encoded BERElement.");

                this.value = bytes[startOfValue .. cursor-1u].dup;
                return ++cursor;
            }
        }
        else // Definite Short
        {
            ubyte length = (bytes[cursor] & 0x7Fu);

            if (cursor+length >= bytes.length)
                throw new ASN1ValueTooSmallException
                ("BER-encoded value terminated prematurely.");

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
                    size_t length = cast(size_t) this.value.length;
                    ubyte[] lengthNumberOctets = cast(ubyte[]) *cast(ubyte[size_t.sizeof] *) &length;
                    version (LittleEndian) reverse(lengthNumberOctets);
                    size_t startOfNonPadding = 0u;
                    for (size_t i = 0u; i < size_t.sizeof; i++)
                    {
                        if (lengthNumberOctets[i] != 0x00u) break;
                        startOfNonPadding++;
                    }
                    lengthNumberOctets = lengthNumberOctets[startOfNonPadding .. $];
                    lengthOctets = [ cast(ubyte) (0x80u + lengthNumberOctets.length) ];
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
        0x08u, 0x0Bu, 0x06u, 0x03u, 0x29u, 0x05u, 0x07u, 0x82u, 
        0x04u, 0x01u, 0x02u, 0x03u, 0x04u ];
    immutable ubyte[] dataReal = [ 0x09u, 0x03u, 0x80u, 0xFBu, 0x05u ]; // 0.15625 (From StackOverflow question)
    immutable ubyte[] dataEnum = [ 0x0Au, 0x01u, 0x3Fu ];
    immutable ubyte[] dataEmbeddedPDV = [ 
        0x0Bu, 0x0Au, 0x80u, 0x02u, 0x85u, 0x00u, 0x82u, 0x04u, 
        0x01u, 0x02u, 0x03u, 0x04u ];
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
        0x1Du, 0x0Fu, 0x80u, 0x06u, 0x81u, 0x04u, 0x29u, 0x06u, 
        0x04u, 0x01u, 0x82u, 0x05u, 0x48u, 0x45u, 0x4Eu, 0x4Cu, 
        0x4Fu ];
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

    CERElement[] result;

    size_t i = 0u;
    while (i < data.length)
        result ~= new CERElement(i, data);

    // Pre-processing
    External x = result[8].external;
    EmbeddedPDV m = result[11].embeddedPresentationDataValue;
    CharacterString c = result[25].characterString;

    // Ensure accessors decode the data correctly.
    assert(result[1].boolean == true);
    assert(result[2].integer!long == 27L);
    assert(result[3].bitString == [ true, true, true, true, false, false, false, false, true ]);
    assert(result[4].octetString == [ 0xFFu, 0x00u, 0x88u, 0x14u ]);
    assert(result[6].objectIdentifier == new OID(OIDNode(0x01u), OIDNode(0x03u), OIDNode(0x06u), OIDNode(0x04u), OIDNode(0x01u)));
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert((x.identification.syntax == new OID(1u, 1u, 5u, 7u)) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[9].realType!float == 0.15625);
    assert(result[9].realType!double == 0.15625);
    assert(result[10].enumerated!long == 63L);
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
        result ~= new CERElement(data);

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
    assert((x.identification.syntax == new OID(1u, 1u, 5u, 7u)) && (x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]));
    assert(result[9].realType!float == 0.15625);
    assert(result[9].realType!double == 0.15625);
    assert(result[10].enumerated!long == 63L);
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

    CERElement[] result;
    size_t i = 0u;
    while (i < data.length)
        result ~= new CERElement(i, data);
        
    assert(result.length == 3);
    assert(result[0].utf8String[0 .. 5] == "AMREN");
    assert(result[1].utf8String[6 .. 14] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');

    result = [];
    while (data.length > 0)
        result ~= new CERElement(data);
        
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
    
    CERElement[] result;
    size_t i = 0u;
    while (i < data.length)
        result ~= new CERElement(i, data);
        
    assert(result.length == 3);
    assert(result[0].utf8String[0 .. 5] == "AMREN");
    assert(result[1].utf8String[6 .. 14] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');

    result = [];
    while (data.length > 0)
        result ~= new CERElement(data);

    assert(result.length == 3);
    assert(result[0].utf8String[0 .. 5] == "AMREN");
    assert(result[1].utf8String[6 .. 14] == "BORTHERS");
    assert(result[2].utf8String[$-2] == '!');
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

    CERElement el;
    assertNotThrown!Exception(el = new CERElement(test));
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
        ubyte[] data = [i]; // REVIEW: Make this immutable
        assertThrown!Exception(new CERElement(data));
    }

    size_t index;
    for (ubyte i = 0x00u; i < ubyte.max; i++)
    {
        ubyte[] data = [i]; // REVIEW: Make this immutable
        assertThrown!Exception(new CERElement(index, data));
    }
}

// Test long-form tag number (when # >= 31) with leading zero bytes (0x80)
@system
unittest
{
    ubyte[] invalid;
    invalid = [ 0b10011111u, 0b10000000u ];
    assertThrown!ASN1TagException(new CERElement(invalid));

    invalid = [ 0b10011111u, 0b10000000u, 0b10000000u ];
    assertThrown!ASN1TagException(new CERElement(invalid));

    invalid = [ 0b10011111u, 0b10000000u, 0b10000111u ];
    assertThrown!ASN1TagException(new CERElement(invalid));
}

// Test long-form tag numbers do not encode with leading zeroes
@system
unittest
{
    ubyte[] invalid;
    CERElement element = new CERElement();
    element.tagNumber = 73u;
    assert((element.toBytes)[1] != 0x80u);
}

// Test that a value that is a byte too short does not throw a RangeError.
@system
unittest
{
    ubyte[] test = [ 0x00u, 0x03u, 0x00u, 0x00u ];
    assertThrown!ASN1ValueTooSmallException(new CERElement(test));
}

// Test that a misleading definite-long length byte does not throw a RangeError.
@system
unittest
{
    ubyte[] invalid = [ 0b0000_0000u, 0b1000_0001u ];
    assertThrown!ASN1ValueTooSmallException(new CERElement(invalid)); // FIXME: Change this exception!
}

// Test that leading zeroes in definite long length encodings throw exceptions
@system
unittest
{
    ubyte[] invalid = [ 0b0000_0000u, 0b1000_0010u, 0b0000_0000u, 0b0000_0001u ];
    assertThrown!ASN1InvalidLengthException(new CERElement(invalid));
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
    assertThrown!ASN1ValueTooSmallException(new CERElement(big));
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
    assertThrown!ASN1ValueTooBigException(new CERElement(big));
}

// Test that a short indefinite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x1F, 0x00u, 0x80, 0x00u ];
    size_t bytesRead = 0u;
    assertThrown!ASN1ValueTooSmallException(new CERElement(bytesRead, naughty));
}

// Test that a short indefinite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x1F, 0x00u, 0x80, 0x00u, 0x00u ];
    size_t bytesRead = 0u;
    assertNotThrown!ASN1ValueTooSmallException(new CERElement(bytesRead, naughty));
}

// Test that a valueless long-form definite-length element does not throw a RangeError
@system
unittest
{
    ubyte[] naughty = [ 0x00u, 0x82, 0x00u, 0x01u ];
    size_t bytesRead = 0u;
    assertThrown!ASN1InvalidLengthException(new CERElement(bytesRead, naughty));
}

// PyASN1 Comparison Testing
@system
unittest
{
    CERElement e = new CERElement();
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