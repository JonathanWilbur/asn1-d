module codecs.ber;
import asn1;
import codec;
import types.alltypes;
import types.identification;
import std.algorithm.mutation : reverse;
import std.bitmanip : BitArray;
import std.datetime.date : DateTime;
import std.outbuffer; // This is only used for OID and ROID...

// Could be useful: http://asn1-playground.oss.com/
// Cite PyASN1 as a source.
// NOTE: ASN1 INTEGERs are Big-Endian! Mac OS X and Linux are Little-Endian!

// REVIEW: Should I change all properties to methods, and renamed them to encode*()?
// REVIEW: Should I change the name of the class?

debug
{
    import std.stdio : writefln, writeln;
}

version (unittest)
{
    import std.exception : assertThrown;
}

///
alias BERException = BasicEncodingRulesException;
///
public
class BasicEncodingRulesException : ASN1CodecException
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

///
alias BERValue = BasicEncodingRulesValue;
///
public
class BasicEncodingRulesValue : ASN1BinaryValue
{
    // TODO: Create static configuration parameters

    // BOOLEAN
    /*
        From the ITU's X.690:
        If the boolean value is TRUE the octet shall have any non-zero value, as a sender's option. 
    */
    override public @property
    bool boolean()
    {
        throwIfEmptyValue!BERException();
        return (this.value[0] ? true : false);
    }

    override public @property
    void boolean(bool value)
    {
        this.value = [(value ? 0xFF : 0x00)];
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.boolean = true;
        assert(bv.boolean == true);
        bv.boolean = false;
        assert(bv.boolean == false);
    }

    // INTEGER
    // TODO: Make this support more types.
    override public @property
    long integer()
    {
        /* NOTE:
            this.value must be duplicated; if it is not, the reverse() operation
            below reverses this.value, which persists until the next decode!
        */
        ubyte[] value = this.value.dup;
        if (value.length > 8)
            throw new BERException
            ("INTEGER is too big to be decoded.");

        version (LittleEndian)
        {
            reverse(value);
        }
        return *cast(long *) value.ptr; // FIXME: This is vulnerable!
    }

    override public @property
    void integer(long value)
    {
        ubyte[] ub;
        ub.length = long.sizeof;
        *cast(long *)&ub[0] = value;
        version (LittleEndian)
        {
            reverse(ub);
        }
        this.value = ub[0 .. $];
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.integer = 1L;
        assert(bv.integer == 1L);

        bv.integer = -300L;
        assert(bv.integer == -300L);

        bv.integer = 65000L;
    }

    // BIT STRING
    override public @property
    BitArray bitString()
    {
        if (this.value[0] > 0x07u)
            throw new BERException
            ("Unused bits byte cannot have a value greater than seven.");
        return BitArray(this.value[1 .. $], cast(size_t) (((this.length - 1u) * 8u) - this.value[0]));
    }

    override public @property
    void bitString(BitArray value)
    {
        // REVIEW: is 0x08u - (value.length % 0x08u) == 0x08u % value.length?
        size_t bitsNeeded = value.length; // value.length is the length in bits, not bytes.
        while (bitsNeeded % 8u) bitsNeeded++; // round up to the nearest byte.
        size_t bytesNeeded = bitsNeeded / 8u;
        ubyte[] valueBytes = cast(ubyte[]) (cast(void[]) value);
        valueBytes.length = bytesNeeded;
        this.value = [ cast(ubyte) (0x08u - (value.length % 0x08u)) ] ~ valueBytes;
    }

    ///
    @system
    unittest
    {
        BitArray ba = BitArray([true, false, true, true, false]);
        BERValue bv = new BERValue();
        bv.bitString = ba;
        assert(bv.bitString == ba);
    }

    // OCTET STRING
    override public @property
    ubyte[] octetString()
    {
        return this.value;
    }

    override public @property
    void octetString(ubyte[] value)
    {
        this.value = value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.octetString = [ 0x05u, 0x02u, 0xFF, 0x00, 0x6A ];
        assert(bv.octetString == [ 0x05u, 0x02u, 0xFF, 0x00, 0x6A ]);
    }

    // NULL
    override public @property
    ubyte[] nill()
    {
        if (this.length != 0)
            throw new BERException
            ("NULL could not be decoded when there are more than zero value bytes.");
        return [];
    }

    override public @property
    void nill(ubyte[] value)
    {
        this.value = [];
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.nill = [];
        assert(bv.nill == []);
    }

    // OBJECT IDENTIFIER
    override public @property
    OID objectIdentifier()
    {
        ulong[] oidComponents = [ (this.value[0] / 0x28u), (this.value[0] % 0x28u) ];

        // The loop below breaks the bytes into components.
        ubyte[][] components;
        ptrdiff_t lastTerminator = 1;
        for (int i = 1; i < this.length; i++)
        {
            if (!(this.value[i] & 0x80u))
            {
                components ~= this.value[lastTerminator .. i+1];
                lastTerminator = i+1;
            }
        }

        // The loop below converts each array of bytes (component) into a ulong, and appends it.
        foreach (component; components)
        {
            oidComponents ~= 0u;
            for (ptrdiff_t i = 0; i < component.length; i++)
            {
                oidComponents[$-1] <<= 7;
                oidComponents[$-1] |= cast(ulong) (component[i] & 0x7Fu);
            }
        }

        return new OID(oidComponents);
    }

    override public @property
    void objectIdentifier(OID value)
    {
        ulong[] oidComponents = value.numericArray();
        if (oidComponents.length == 1) oidComponents ~= 0L; // So the next line does not fail.
        this.value = [ cast(ubyte) (oidComponents[0] * 40u + oidComponents[1]) ]; //FIXME: This might be suceptable to overflow attacks.
        if (oidComponents.length > 2)
        {
            foreach (x; oidComponents[2 .. $])
            {
                ubyte[] encodedOIDComponent;
                if (x == 0) // REVIEW: Could you make this faster by using if (x < 128)?
                {
                    this.value ~= 0x00;
                    continue;
                }
                while (x != 0)
                {
                    OutBuffer ob = new OutBuffer();
                    ob.write(x);
                    ubyte[] compbytes = ob.toBytes();
                    if ((compbytes[0] & 0x80) == 0) compbytes[0] |= 0x80;
                    encodedOIDComponent = compbytes[0] ~ encodedOIDComponent;
                    x >>= 7;
                }
                encodedOIDComponent[$-1] &= 0x7F;
                this.value ~= encodedOIDComponent;
            }
        }
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.objectIdentifier = new OID(1u, 30u, 256u, 623485u, 8u);
        // FIXME: I think this unittest fails without .numericArray because I have not designed opCmp() for OID well.
        assert(bv.objectIdentifier.numericArray ==  (new OID(1u, 30u, 256u, 623485u, 8u)).numericArray);
    }

    // ObjectDescriptor
    override public @property
    string objectDescriptor()
    {
        import std.ascii : isGraphical;
        foreach (character; this.value)
        {
            if (!character.isGraphical)
            {
                throw new BERException(
                    "Object descriptor can only contain graphical characters. '"
                    ~ character ~ "' is not graphical.");
            }
        }
        return cast(string) this.value;
    }

    override public @property
    void objectDescriptor(string value)
    {
        import std.ascii : isGraphical;
        foreach (character; value)
        {
            if (!character.isGraphical)
            {
                throw new BERException(
                    "Object descriptor can only contain graphical characters. '"
                    ~ character ~ "' is not graphical.");
            }
        }
        this.value = cast(ubyte[]) value;
    }

    // EXTERNAL
    /* REVIEW:
        Is there some way to abstract the types into the parent class?
    */
    /** NOTE:
        Also found in X.680, Section 37.5.

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 2.

        Duboisson Book, Page 303:

        EXTERNAL := [UNIVERSAL 8] IMPLICIT SEQUENCE {
            identification CHOICE {
                syntax OBJECT IDENTIFIER,
                presentation-context-id INTEGER,
                context-negotiation SEQUENCE {
                    presentation-context-id INTEGER,
                    transfer-syntax OBJECT IDENTIFIER } },
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }

    */
    override public @property
    External external()
    {
        BERValue[] bvs = this.sequence;
        if (bvs.length < 2 || bvs.length > 3)
            throw new BERException
            ("Improper number of elements in EXTERNAL type.");

        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();
        External ext = External();

        foreach (bv; bvs)
        {
            switch (bv.type)
            {
                case (0x80u): // identification
                {
                    BERValue identificationBV = new BERValue(bv.value);
                    switch(identificationBV.type)
                    {
                        case (0x80u): // syntax
                        {
                            identification.syntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x81u): // presentation-context-id
                        {
                            identification.presentationContextID = identificationBV.integer;
                            break;
                        }
                        case (0x82u): // context-negotiation
                        {
                            // REVIEW: Should this be split off into a separate function?
                            ASN1ContextNegotiation contextNegotiation = ASN1ContextNegotiation();
                            BERValue[] cns = identificationBV.sequence;
                            if (cns.length != 2)
                                throw new BERException
                                ("Invalid number of elements in EXTERNAL.identification.context-negotiation");
                            
                            foreach (cn; cns)
                            {
                                switch (cn.type)
                                {
                                    case (0x80u): // presentation-context-id
                                    {
                                        contextNegotiation.presentationContextID = cn.integer;
                                        break;
                                    }
                                    case (0x81u): // transfer-syntax
                                    {
                                        contextNegotiation.transferSyntax = cn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new BERException
                                        ("Invalid EXTERNAL.identification.context-negotiation tag.");
                                    }
                                }
                            }
                            identification.contextNegotiation = contextNegotiation;
                            break;
                        }
                        default:
                        {
                            throw new BERException
                            ("Invalid EXTERNAL.identification choice.");
                        }
                    }
                    ext.identification = identification;
                    break;
                }
                case (0x81u): // data-value-descriptor
                {
                    ext.dataValueDescriptor = bv.objectDescriptor;
                    break;
                }
                case (0x82u): // data-value
                {
                    ext.dataValue = bv.octetString;
                    break;
                }
                default:
                {
                    throw new BERException
                    ("Invalid EXTERNAL context-specific tag.");
                }
            }
        }
        return ext;
    }

    // REVIEW: The type tags below might be wrong... (Primitive? Constructed?)
    override public @property
    void external(External value)
    {
        BERValue identification = new BERValue();
        identification.type = 0x80u; // CHOICE is EXPLICIT, even with automatic tagging.

        BERValue identificationValue = new BERValue();
        if (!(value.identification.syntax.isNull))
        {
            identificationValue.type = 0x80u;
            identificationValue.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.contextNegotiation.isNull))
        {
            BERValue presentationContextID = new BERValue();
            presentationContextID.type = 0x80u;
            presentationContextID.integer = value.identification.contextNegotiation.presentationContextID;
            
            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x81u;
            transferSyntax.objectIdentifier = value.identification.contextNegotiation.transferSyntax;
            
            identificationValue.type = 0x82u;
            identificationValue.sequence = [ presentationContextID, transferSyntax ];
        }
        else // it must be the presentationContextID INTEGER
        {
            identificationValue.type = 0x81u;
            identificationValue.integer = value.identification.presentationContextID;
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationValue;

        BERValue dataValueDescriptor = new BERValue();
        dataValueDescriptor.type = 0x81u; // Primitive ObjectDescriptor
        dataValueDescriptor.objectDescriptor = value.dataValueDescriptor;

        BERValue dataValue = new BERValue();
        dataValue.type = 0x82u;
        dataValue.octetString = value.dataValue;

        this.sequence = [ identification, dataValueDescriptor, dataValue ];
    }

    ///
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        External ext = External();
        ext.identification = id;
        ext.dataValueDescriptor = "external";
        ext.dataValue = [ 0x01u, 0x02u, 0x03u, 0x04u ];

        BERValue bv = new BERValue();
        bv.type = 0x08;
        bv.external = ext;
        assert(bv.toBytes() == [ 0x08, 0x1C, 0x80, 0x0A, 0x81, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1B, 0x81, 0x08, 0x65, 0x78, 0x74, 0x65, 0x72, 0x6E, 0x61, 0x6C, 0x82, 0x04, 0x01, 0x02, 0x03, 0x04 ]);

        External x = bv.external;
        assert(x.identification.presentationContextID == 27L);
        assert(x.dataValueDescriptor == "external");
        assert(x.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]);
    }

    // REAL
    public @property
    T realType(T)() if (is(T == float) || is(T == double))
    {
        // import std.array : split;
        import std.conv : ConvException, ConvOverflowException, to;

        if (this.length == 0) return cast(T) 0.0;

        switch (this.value[0] & 0b_1100_0000)
        {
            case (0b_0100_0000):
            {
                return ((this.value[0] & 0b_0011_1111) ? T.infinity : -T.infinity);
            }
            case (0b_0000_0000): // Character Encoding
            {
                string chars = cast(string) this.value[1 .. $];

                try 
                {
                    return to!(T)(chars);
                }
                catch (ConvOverflowException coe)
                {
                    throw new BERException
                    ("Character-encoded REAL is too large to translate to a native floating-point type.");
                }
                catch (ConvException ce)
                {
                    throw new BERException
                    ("Character-encoded REAL could not be decoded to a native floating-point type.");
                }

                // size_t i;
                // ptrdiff_t decimalPointIndex = -1;
                // ptrdiff_t exponentOperatorIndex = -1; // 'e' or 'E'

                // if (chars[0] >= '0' && chars[0] <= '9')
                // {
                //     ret = 0.0;
                // }
                // else if (chars[0] == '+')
                // {
                //     ret = 0.0;
                //     i++;
                // }
                // else if (chars[0] == '.')
                // {
                //     ret = 0.0;
                //     i++;
                //     decimalPointIndex = 0;
                // }
                // else
                // {
                //     ret = -0.0;
                //     i++;
                // }

                // while (i < chars.length)
                // {
                //     if (exponentOperatorEncountered && (chars[i] == 'e' || chars[i] == 'E'))
                //         throw new BERException
                //         ("Invalid character-encoded REAL; has two or more 'E's.");
                //     if (exponentOperatorEncountered && chars[i] == '.')
                //         throw new BERException
                //         ("Invalid character-encoded REAL; has two or more '.'s.");
                // }

                // long mantissa;
                // try 
                // {
                //     mantissa = exponentOperatorEncountered ? 
                // }
                // catch (ConvOverflowException)
                // {

                // }
                // catch (ConvException ce)
                // {

                // }

                // switch (this.value[0] & 0b_0011_1111)
                // {
                //     case (0b_0000_0001): // NR1
                //     {
                //         // 3, -1, +1000
                //     }
                //     case (0b_0000_0010): // NR2
                //     {
                //         // 3.0, -1.3, -.3
                //     }
                //     case (0b_0000_0011): // NR3
                //     {
                //         // 3.0E1, 123E+100
                //     }
                //     default:
                //     {
                //         throw new BERException
                //         ("Invalid Numeric Representation for REAL selected.");
                //     }
                // }
            }
            case 0b_1000_0000, 0b_1100_0000: // Binary Encoding
            {
                ulong mantissa;
                long exponent;
                ubyte scale;
                ubyte base;
                RealBinaryEncodingBase realBinaryEncodingBase = RealBinaryEncodingBase.base2;

                // There must be at least one information byte and one exponent byte.
                if (this.length < 2)
                    throw new BERException
                    ("REAL value has too few bytes. Only an information byte was found.");

                switch (this.value[0] & 0b00000011)
                {
                    case 0b00000000: // Exponent on the following octet
                    {
                        /*
                            this.value[1] has to be cast to a byte first so that it
                            acquires a sign.
                        */
                        exponent = cast(long) cast(byte) this.value[1];

                        if (this.length - 2 > 8)
                            throw new BERException
                            ("REAL mantissa is too big for this encoder.");

                        ubyte m = 0x02u;
                        while (m < this.length)
                        {
                            mantissa <<= 8;
                            mantissa += this.value[m];
                            m++;
                        }

                        break;
                    }
                    case 0b00000001: // Exponent on the following two octets
                    {
                        if (this.length == 2)
                            throw new BERException
                            ("REAL value has too few bytes.");

                        // void[2] exponentBytes = *cast(void[2] *) &(this.value[1]);
                        ubyte[] exponentBytes = this.value[1 .. 3].dup;
                        version (LittleEndian)
                        {
                            reverse(exponentBytes);
                        }
                        exponent = cast(long) (*cast(short *) exponentBytes.ptr);

                        if (this.length - 3 > 8)
                            throw new BERException
                            ("REAL mantissa is too big for this encoder.");

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
                        version (BigEndian)
                        {
                            while (this.length - m > 0)
                            {
                                mantissa <<= 8;
                                mantissa += this.value[m];
                                m--;
                            }
                        }

                        break;
                    }
                    case 0b00000010: // Exponent on the following three octets
                    {
                        if (this.length == 4)
                            throw new BERException
                            ("REAL value has too few bytes.");

                        exponent = cast(long) ((*cast(int *) cast(void[4] *) &(this.value[1])) & 0x00FFFFFF);

                        if (this.length - 4 > 8)
                            throw new BERException
                            ("REAL mantissa is too big for this encoder.");

                        ubyte m = 0x03u;
                        while (m < this.length)
                        {
                            mantissa <<= 8;
                            mantissa += this.value[m];
                            m++;
                        }
                        break;
                    }
                    case 0b00000011: // Complicated
                    {
                        if (this.length == 1)
                            throw new BERException
                            ("REAL value has too few bytes.");
                        
                        ubyte exponentLength = this.value[1];

                        if (this.length == (exponentLength - 0x01u))
                            throw new BERException
                            ("REAL value has too few bytes.");

                        if (exponentLength > 0x08u)
                            throw new BERException
                            ("REAL value exponent is too big.");

                        ubyte i = 0x00u;
                        while (i < exponentLength)
                        {
                            exponent <<= 8;
                            exponent += this.value[i];
                            i++;
                        }

                        if (this.length - 1 - exponentLength > 8)
                            throw new BERException
                            ("REAL mantissa is too big for this encoder.");

                        ubyte m = 0x01u;
                        while (m < this.length)
                        {
                            mantissa <<= 8;
                            mantissa += this.value[m];
                            m++;
                        }
                        break;
                    }
                    default:
                    {
                        assert(0, "Impossible binary exponent encoding on REAL type");
                    }
                }

                switch (this.value[0] & 0b_0011_0000)
                {
                    case (0b_0000_0000): // Base 2
                    {
                        base = 0x02u;
                        break;
                    }
                    case (0b_0000_0001): // Base 8
                    {
                        base = 0x08u;
                        break;
                    }
                    case (0b_0000_0010): // Base 16
                    {
                        base = 0x10u;
                        break;
                    }
                    default:
                    {
                        throw new BERException
                        ("Invalid binary-encoded REAL base");
                    }
                }

                scale = ((this.value[0] & 0b_0000_1100) >> 2);

                return (
                    ((this.value[0] & 0b_0100_0000) ? -1 : 1) *
                    mantissa *
                    2^^scale *
                    (cast(T) base)^^exponent // base needs to be cast
                );
            }
            default:
            {
                throw new BERException
                ("Invalid information block for REAL type.");
            }
        }
    }

    public @property
    void realType(T)(T value)
    if (is(T == float) || is(T == double))
    {
        import std.bitmanip : DoubleRep, FloatRep;

        bool positive = true;
        real significand;
        RealEncodingScale scalingFactor = RealEncodingScale.scale0;
        RealEncodingBase base = RealEncodingBase.base2;
        RealBinaryEncodingBase realBinaryEncodingBase = RealBinaryEncodingBase.base2;
        short exponent = 0;

        if (value == T.nan)
        {
            throw new BERException("ASN1 cannot encode NaN");
        }
        else if (value == T.infinity)
        {
            this.value = [ 0x01, 0x40 ];
        }
        else if (value == -T.infinity)
        {
            this.value = [ 0x01, 0x41 ];
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
            significand = (valueUnion.fraction | 0x0010000000000000); // Flip bit #53
        }
        static if (is(T == float))
        {
            FloatRep valueUnion = FloatRep(value);
            significand = (valueUnion.fraction | 0x00800000); // Flip bit #24
        }

        // IEEE floating-point types use a set first bit to indicate a negative.
        positive = (valueUnion.sign ? false : true);

        // See comment below.
        exponent = cast(short)
            (valueUnion.exponent - valueUnion.bias - valueUnion.fractionBits);

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

        /* FIXME:
            Converting from a significand of type real to uint or ulong means that an overflow
            exception is highly possible.
        */
        ubyte[] exponentBytes;
        exponentBytes.length = short.sizeof;
        *cast(short *)exponentBytes.ptr = exponent;
        version (LittleEndian)
        {
            reverse(exponentBytes);
        }
        
        ubyte[] significandBytes;
        significandBytes.length = ulong.sizeof;
        *cast(ulong *)significandBytes.ptr = cast(ulong) significand;
        version (LittleEndian)
        {
            reverse(significandBytes);
        }

        ubyte infoByte =
            0x80 | // First bit gets set for base2, base8, or base16 encoding
            (positive ? 0x00 : 0x40) | // 1 = negative, 0 = positive
            realBinaryEncodingBase | // Bitmask specifying base
            RealEncodingScales.scale0 |
            RealExponentEncoding.following2Octets;

        this.value = (infoByte ~ exponentBytes ~ significandBytes);
    }

    // TODO: Test a LOT of values here.
    ///
    @system
    unittest
    {
        import std.math : approxEqual;
        /*
            After a VERY long Sunday morning, I finally figured out that the
            most significant byte is going to be the left-most byte in the
            BER-encoded REAL. Thanks, pyasn1!
        */
        float f = 22.86;
        double d = 0.00583;
        BERValue bvf = new BERValue();
        BERValue bvd = new BERValue();
        bvf.realType!float = f;
        bvd.realType!double = d;
        assert(approxEqual(bvf.realType!float, f));
        assert(approxEqual(bvf.realType!double, f));
        assert(approxEqual(bvd.realType!float, d));
        assert(approxEqual(bvd.realType!double, d));
    }

    // ENUMERATED
    override public @property
    long enumerated()
    {
        /* NOTE:
            this.value must be duplicated; if it is not, the reverse() operation
            below reverses this.value, which persists until the next decode!
        */
        ubyte[] value = this.value.dup;
        if (value.length > 8)
            throw new BERException
            ("ENUMERATED is too big to be decoded.");

        version (LittleEndian)
        {
            reverse(value);
        }
        return *cast(long *) value.ptr; // FIXME: This is vulnerable!
    }

    override public @property
    void enumerated(long value)
    {
        ubyte[] ub;
        ub.length = long.sizeof;
        *cast(long *)&ub[0] = value;
        version (LittleEndian)
        {
            reverse(ub);
        }
        this.value = ub[0 .. $];
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.enumerated = 5L;
        assert(bv.enumerated == 5L);
    }

    // EMBEDDED PDV
    /**

    This definition below assumes AUTOMATIC TAGS.

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

    */
    override public @property
    EmbeddedPDV embeddedPDV()
    {
        BERValue[] bvs = this.sequence;
        if (bvs.length < 2 || bvs.length > 3)
            throw new BERException
            ("Improper number of elements in EMBEDDED PDV type.");

        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();
        EmbeddedPDV pdv = EmbeddedPDV();

        foreach (bv; bvs)
        {
            switch (bv.type)
            {
                case (0x80u): // identification
                {
                    BERValue identificationBV = new BERValue(bv.value);
                    switch (identificationBV.type)
                    {
                        case (0x80u): // syntaxes
                        {
                            ASN1ContextSwitchingTypeSyntaxes syntaxes = ASN1ContextSwitchingTypeSyntaxes();
                            BERValue[] syns = identificationBV.sequence;
                            if (syns.length != 2)
                                throw new BERException
                                ("Invalid number of elements in EMBEDDED PDV.identification.syntaxes");

                            foreach (syn; syns)
                            {
                                switch (syn.type)
                                {
                                    case (0x80u): // abstract
                                    {
                                        syntaxes.abstractSyntax = syn.objectIdentifier;
                                        break;
                                    }
                                    case (0x81): // transfer
                                    {
                                        syntaxes.transferSyntax = syn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new BERException
                                        ("Invalid EMBEDDED PDV.identification.syntaxes tag.");
                                    }
                                }
                            }
                            identification.syntaxes = syntaxes;
                            break;
                        }
                        case (0x81u): // syntax
                        {
                            identification.syntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x82u): // presentation-context-id
                        {
                            identification.presentationContextID = identificationBV.integer;
                            break;
                        }
                        case (0x83u): // context-negotiation
                        {
                            // REVIEW: Should this be split off into a separate function?
                            ASN1ContextNegotiation contextNegotiation = ASN1ContextNegotiation();
                            BERValue[] cns = identificationBV.sequence;
                            if (cns.length != 2)
                                throw new BERException
                                ("Invalid number of elements in EMBEDDED PDV.identification.context-negotiation");
                            
                            foreach (cn; cns)
                            {
                                switch (cn.type)
                                {
                                    case (0x80u): // presentation-context-id
                                    {
                                        contextNegotiation.presentationContextID = cn.integer;
                                        break;
                                    }
                                    case (0x81u): // transfer-syntax
                                    {
                                        contextNegotiation.transferSyntax = cn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new BERException
                                        ("Invalid EMBEDDED PDV.identification.context-negotiation tag.");
                                    }
                                }
                            }
                            identification.contextNegotiation = contextNegotiation;
                            break;
                        }
                        case (0x84u): // transfer-syntax
                        {
                            identification.transferSyntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x85u): // fixed
                        {
                            identification.fixed = true;
                            break;
                        }
                        default:
                        {
                            throw new BERException
                            ("Invalid EMBEDDED PDV.identification choice.");
                        }
                    }
                    pdv.identification = identification;
                    break;
                }
                case (0x81u): // data-value-descriptor
                {
                    pdv.dataValueDescriptor = bv.objectDescriptor;
                    break;
                }
                case (0x82u): // data-value
                {
                    pdv.dataValue = bv.octetString;
                    break;
                }
                default:
                {
                    throw new BERException
                    ("Invalid EMBEDDED PDV context-specific tag.");
                }
            }
        }
        return pdv;
    }

    override public @property
    void embeddedPDV(EmbeddedPDV value)
    {
        BERValue identification = new BERValue();
        identification.type = 0x80u; // CHOICE is EXPLICIT, even with automatic tagging.

        BERValue identificationValue = new BERValue();
        if (!(value.identification.syntaxes.isNull))
        {
            BERValue abstractSyntax = new BERValue();
            abstractSyntax.type = 0x81u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x82u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationValue.type = 0x80u;
            identificationValue.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationValue.type = 0x81u;
            identificationValue.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.contextNegotiation.isNull))
        {
            BERValue presentationContextID = new BERValue();
            presentationContextID.type = 0x80u;
            presentationContextID.integer = value.identification.contextNegotiation.presentationContextID;
            
            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x81u;
            transferSyntax.objectIdentifier = value.identification.contextNegotiation.transferSyntax;
            
            identificationValue.type = 0x83u;
            identificationValue.sequence = [ presentationContextID, transferSyntax ];
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationValue.type = 0x84u;
            identificationValue.objectIdentifier = value.identification.transferSyntax;
        }
        else if (value.identification.fixed)
        {
            identificationValue.type = 0x85u;
            identificationValue.nill = [];
        }
        else // it must be the presentationContextID INTEGER
        {
            identificationValue.type = 0x82u;
            identificationValue.integer = value.identification.presentationContextID;
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationValue;

        BERValue dataValueDescriptor = new BERValue();
        dataValueDescriptor.type = 0x81u; // Primitive ObjectDescriptor
        dataValueDescriptor.objectDescriptor = value.dataValueDescriptor;

        BERValue dataValue = new BERValue();
        dataValue.type = 0x82u;
        dataValue.octetString = value.dataValue;

        this.sequence = [ identification, dataValueDescriptor, dataValue ];
    }

    ///
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 27L;

        EmbeddedPDV pdv = EmbeddedPDV();
        pdv.identification = id;
        pdv.dataValueDescriptor = "AAAABBBB";
        pdv.dataValue = [ 0x01u, 0x02u, 0x03u, 0x04u ];

        BERValue bv = new BERValue();
        bv.embeddedPDV = pdv;
        // writefln("Embedded PDV: %(%02X %)", cast(ubyte[]) bv);

        EmbeddedPDV pdv2 = bv.embeddedPDV;
        assert(pdv2.identification.presentationContextID == 27L);
        assert(pdv2.dataValueDescriptor == "AAAABBBB");
        assert(pdv2.dataValue == [ 0x01u, 0x02u, 0x03u, 0x04u ]);
    }

    // UTF8String
    override public @property
    string utf8string()
    {
        return cast(string) this.value;
    }

    override public @property
    void utf8string(string value)
    {
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.utf8string = "henlo borthers";
        assert(bv.utf8string == "henlo borthers");
    }

    // RELATIVE OID
    override public @property
    RelativeOID relativeObjectIdentifier()
    {
        ulong[] oidComponents = [];

        // The loop below breaks the bytes into components.
        ubyte[][] components;
        ptrdiff_t lastTerminator = 0;
        for (int i = 0; i < this.length; i++)
        {
            if (!(this.value[i] & 0x80u))
            {
                components ~= this.value[lastTerminator .. i+1];
                lastTerminator = i+1;
            }
        }

        // The loop below converts each array of bytes (component) into a ulong, and appends it.
        foreach (component; components)
        {
            oidComponents ~= 0u;
            for (ptrdiff_t i = 0; i < component.length; i++)
            {
                oidComponents[$-1] <<= 7;
                oidComponents[$-1] |= cast(ulong) (component[i] & 0x7Fu);
            }
        }

        return new RelativeOID(oidComponents);
    }

    override public @property
    void relativeObjectIdentifier(RelativeOID value)
    {
        ulong[] oidComponents = value.numericArray();
        foreach (x; oidComponents)
        {
            ubyte[] encodedOIDComponent;
            if (x == 0) // REVIEW: Could you make this faster by using if (x < 128)?
            {
                this.value ~= 0x00;
                continue;
            }
            while (x != 0)
            {
                OutBuffer ob = new OutBuffer();
                ob.write(x);
                ubyte[] compbytes = ob.toBytes();
                if ((compbytes[0] & 0x80) == 0) compbytes[0] |= 0x80;
                encodedOIDComponent = compbytes[0] ~ encodedOIDComponent;
                x >>= 7;
            }
            encodedOIDComponent[$-1] &= 0x7F;
            this.value ~= encodedOIDComponent;
        }
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.relativeObjectIdentifier = new RelativeOID(3uL, 5uL, 7uL, 9uL, 4uL);
        assert(bv.relativeObjectIdentifier.numericArray == [ 3L, 5L, 7L, 9L, 4L ]);
    }

    // SEQUENCE
    public @property
    BERValue[] sequence()
    {
        ubyte[] data = this.value.dup;
        BERValue[] result;
        while (data.length > 0)
            result ~= new BERValue(data);
        return result;
    }

    public @property
    void sequence(BERValue[] value)
    {
        ubyte[] result;
        foreach (bv; value)
        {
            result ~= cast(ubyte[]) bv;
        }
        this.value = result;
    }

    // SET
    public @property
    BERValue[] set()
    {
        ubyte[] data = this.value.dup;
        BERValue[] result;
        while (data.length > 0)
            result ~= new BERValue(data);
        return result;
    }

    public @property
    void set(BERValue[] value)
    {
        ubyte[] result;
        foreach (bv; value)
        {
            result ~= cast(ubyte[]) bv;
        }
        this.value = result;
    }

    // NumericString
    override public @property
    string numericString()
    {
        // import std.algorithm.searching : any;
        // import std.ascii : isDigit;
        return cast(string) this.value;
        // return (new NumericString(cast (string) this.value)).value;
    }

    override public @property
    void numericString(string value)
    {
        import std.algorithm.searching : canFind;
        foreach (character; value)
        {
            if (!canFind("1234567890 ", character))
                throw new BERException
                ("NUMERIC STRING only accepts numbers and spaces.");
        }
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.numericString = "1234567890";
        assert(bv.numericString == "1234567890");
        assertThrown!BERException(bv.numericString = "hey hey");
    }

    // PrintableString
    override public @property
    string printableString()
    {
        return cast(string) this.value;
    }

    override public @property
    void printableString(string value)
    {
        import std.ascii : isPrintable;
        foreach (character; value)
        {
            if (!character.isPrintable)
                throw new BERException
                ("PRINTABLE STRING only accepts printable characters or space.");
        }
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.printableString = "1234567890 asdfjkl;";
        assert(bv.printableString == "1234567890 asdfjkl;");
        assertThrown!BERException(bv.printableString = "\t");
        assertThrown!BERException(bv.printableString = "\n");
        assertThrown!BERException(bv.printableString = "\0");
        assertThrown!BERException(bv.printableString = "\v");
        assertThrown!BERException(bv.printableString = "\b");
        assertThrown!BERException(bv.printableString = "\r");
        assertThrown!BERException(bv.printableString = "\x13");
    }

    // TeletexString
    // REVIEW: This probably needs some validation, but that will come after I finish the Teletex library.
    override public @property
    ubyte[] teletexString()
    {
        return this.value;
    }

    override public @property
    void teletexString(ubyte[] value)
    {
        this.value = value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.teletexString = [ 0x01, 0x03, 0x05, 0x07, 0x09 ];
        assert(bv.teletexString == [ 0x01, 0x03, 0x05, 0x07, 0x09 ]);
    }

    // VideotexString
    // REVIEW: This probably needs some validation, but that will come after I finish the Videotex library.
    override public @property
    ubyte[] videotexString()
    {
        return this.value;
    }

    override public @property
    void videotexString(ubyte[] value)
    {
        this.value = value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.videotexString = [ 0x01, 0x03, 0x05, 0x07, 0x09 ];
        assert(bv.videotexString == [ 0x01, 0x03, 0x05, 0x07, 0x09 ]);
    }

    // IA5String
    override public @property
    string ia5String()
    {
        import std.ascii : isASCII;
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isASCII)
                throw new BERException
                ("IA5String only accepts ASCII characters.");
        }
        return ret;
    }

    override public @property
    void ia5String(string value)
    {
        import std.ascii : isASCII;
        foreach (character; value)
        {
            if (!character.isASCII)
                throw new BERException
                ("IA5String only accepts ASCII characters.");
        }
        this.value = cast(ubyte[]) value;
    } 

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.ia5String = "Nitro dubs & T-Rix";
        assert(bv.ia5String == "Nitro dubs & T-Rix");
        assertThrown!BERException(bv.ia5String = "Nitro dubs \xD7 T-Rix");
    }

    // UTCTime
    override public @property
    DateTime utcTime()
    {
        /*
            If the first digit of the two-digit year 7, 6, 5, 4, 3, 2, 1, or 0, 
            meaning that the date refers to the first 80 years of the century,
            assume we are talking about the 21st century and prepend '20' when
            creating the ISO Date String. Otherwise, assume we are talking about
            the 20th century, and prepend '19' when creating the ISO Date String.
        */
        string dt = (((this.value[0] <= '7') ? "20" : "19") ~ cast(string) this.value);
        return DateTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    override public @property
    void utcTime(DateTime value)
    {
        import std.string : replace;
        this.value = cast(ubyte[]) (value.toISOString()[2 .. $].replace("T", ""));
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.utcTime = DateTime(2017, 10, 3);
        assert(bv.utcTime == DateTime(2017, 10, 3));
    }

    // GeneralizedTime
    override public @property
    DateTime generalizedTime()
    {
        string dt = cast(string) this.value;
        return DateTime.fromISOString(dt[0 .. 8].idup ~ "T" ~ dt[8 .. $].idup);
    }

    override public @property
    void generalizedTime(DateTime value)
    {
        import std.string : replace;
        this.value = cast(ubyte[]) (value.toISOString().replace("T", ""));
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.generalizedTime = DateTime(2017, 10, 3);
        assert(bv.generalizedTime == DateTime(2017, 10, 3));
    }

    // GraphicString
    override public @property
    string graphicString()
    {
        import std.ascii : isGraphical;
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isGraphical && character != ' ')
                throw new BERException
                ("GraphicString only accepts graphic characters and space.");
        }
        return ret;
    }

    override public @property
    void graphicString(string value)
    {
        import std.ascii : isGraphical;
        foreach (character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new BERException
                ("GraphicString only accepts graphic characters and space.");
        }
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.graphicString = "Nitro dubs & T-Rix";
        assert(bv.graphicString == "Nitro dubs & T-Rix");
        assertThrown!BERException(bv.graphicString = "\xD7");
        assertThrown!BERException(bv.graphicString = "\t");
        assertThrown!BERException(bv.graphicString = "\r");
        assertThrown!BERException(bv.graphicString = "\n");
        assertThrown!BERException(bv.graphicString = "\b");
        assertThrown!BERException(bv.graphicString = "\v");
        assertThrown!BERException(bv.graphicString = "\f");
        assertThrown!BERException(bv.graphicString = "\0");
    }

    // VisibleString
    // REVIEW: I am still not sure of the validation for .visibleString()
    override public @property
    string visibleString()
    {
        import std.ascii : isGraphical;
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isGraphical && character != ' ')
                throw new BERException
                ("VisibleString only accepts graphic characters and space.");
        }
        return ret;
    }

    override public @property
    void visibleString(string value)
    {
        import std.ascii : isGraphical;
        foreach (character; value)
        {
            if (!character.isGraphical && character != ' ')
                throw new BERException
                ("VisibleString only accepts graphic characters and space.");
        }
        this.value = cast(ubyte[]) value;
    }

    // GeneralString
    /* REVIEW:
        Delete is supposed to be a control character, but I
        am not sure that isControl() treats it as such.
    */
    override public @property
    string generalString()
    {
        import std.ascii : isControl, isGraphical;
        string ret = cast(string) this.value;
        foreach (character; ret)
        {
            if (!character.isGraphical && !character.isControl && character != ' ')
                throw new BERException
                ("GeneralString only accepts graphic characters, control characters, and space.");
        }
        return ret;
    }

    override public @property
    void generalString(string value)
    {
        import std.ascii : isControl, isGraphical;
        foreach (character; value)
        {
            if (!character.isGraphical && !character.isControl && character != ' ')
                throw new BERException
                ("GeneralString only accepts graphic characters, control characters, and space.");
        }
        this.value = cast(ubyte[]) value;
    }

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.generalString = "foin-ass sweatpants from BUCCI \0\n\t\b\v\r\f";
        assert(bv.generalString == "foin-ass sweatpants from BUCCI \0\n\t\b\v\r\f");
        assertThrown!BERException(bv.generalString = "\xF5");
    }

    // UniversalString
    // REVIEW: Does UTF-32 endianness matter? NOTE: PyASN1 encodes this big-endian..
    override public @property
    dstring universalString()
    {
        version (BigEndian)
        {
            return cast(dstring) this.value;
        }
        version (LittleEndian)
        {
            if (this.value.length % 4)
                throw new BERException
                ("Invalid number of bytes for UniversalString. Must be a multiple of 4.");

            dstring ret;
            ptrdiff_t i = 0;
            while (i < this.value.length-3)
            {
                ubyte[] character;
                character.length = 4;
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

    override public @property
    void universalString(dstring value)
    {
        version (BigEndian)
        {
            this.value = cast(ubyte[]) value;
        }
        version (LittleEndian)
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

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.universalString = "abcd"d;
        assert(bv.universalString == "abcd"d);
    }

    // CHARACTER STRING
    override public @property
    CharacterString characterString()
    {
        BERValue[] bvs = this.sequence;
        if (bvs.length < 2 || bvs.length > 3)
            throw new BERException
            ("Improper number of elements in CharacterString type.");

        ASN1ContextSwitchingTypeID identification = ASN1ContextSwitchingTypeID();
        CharacterString cs = CharacterString();

        foreach (bv; bvs)
        {
            switch (bv.type)
            {
                case (0x80u): // identification
                {
                    BERValue identificationBV = new BERValue(bv.value);
                    switch (identificationBV.type)
                    {
                        case (0x80u): // syntaxes
                        {
                            ASN1ContextSwitchingTypeSyntaxes syntaxes = ASN1ContextSwitchingTypeSyntaxes();
                            BERValue[] syns = identificationBV.sequence;
                            if (syns.length != 2)
                                throw new BERException
                                ("Invalid number of elements in CharacterString.identification.syntaxes");

                            foreach (syn; syns)
                            {
                                switch (syn.type)
                                {
                                    case (0x80u): // abstract
                                    {
                                        syntaxes.abstractSyntax = syn.objectIdentifier;
                                        break;
                                    }
                                    case (0x81): // transfer
                                    {
                                        syntaxes.transferSyntax = syn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new BERException
                                        ("Invalid CharacterString.identification.syntaxes tag.");
                                    }
                                }
                            }
                            identification.syntaxes = syntaxes;
                            break;
                        }
                        case (0x81u): // syntax
                        {
                            identification.syntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x82u): // presentation-context-id
                        {
                            identification.presentationContextID = identificationBV.integer;
                            break;
                        }
                        case (0x83u): // context-negotiation
                        {
                            // REVIEW: Should this be split off into a separate function?
                            ASN1ContextNegotiation contextNegotiation = ASN1ContextNegotiation();
                            BERValue[] cns = identificationBV.sequence;
                            if (cns.length != 2)
                                throw new BERException
                                ("Invalid number of elements in CharacterString.identification.context-negotiation");
                            
                            foreach (cn; cns)
                            {
                                switch (cn.type)
                                {
                                    case (0x80u): // presentation-context-id
                                    {
                                        contextNegotiation.presentationContextID = cn.integer;
                                        break;
                                    }
                                    case (0x81u): // transfer-syntax
                                    {
                                        contextNegotiation.transferSyntax = cn.objectIdentifier;
                                        break;
                                    }
                                    default:
                                    {
                                        throw new BERException
                                        ("Invalid CharacterString.identification.context-negotiation tag.");
                                    }
                                }
                            }
                            identification.contextNegotiation = contextNegotiation;
                            break;
                        }
                        case (0x84u): // transfer-syntax
                        {
                            identification.transferSyntax = identificationBV.objectIdentifier;
                            break;
                        }
                        case (0x85u): // fixed
                        {
                            identification.fixed = true;
                            break;
                        }
                        default:
                        {
                            throw new BERException
                            ("Invalid CharacterString.identification choice.");
                        }
                    }
                    cs.identification = identification;
                    break;
                }
                case (0x81u): // string-value
                {
                    cs.stringValue = bv.octetString;
                    break;
                }
                default:
                {
                    throw new BERException
                    ("Invalid CharacterString context-specific tag.");
                }
            }
        }
        return cs;
    }

    override public @property
    void characterString(CharacterString value)
    {
        BERValue identification = new BERValue();
        identification.type = 0x80u; // CHOICE is EXPLICIT, even with automatic tagging.

        BERValue identificationValue = new BERValue();
        if (!(value.identification.syntaxes.isNull))
        {
            BERValue abstractSyntax = new BERValue();
            abstractSyntax.type = 0x81u;
            abstractSyntax.objectIdentifier = value.identification.syntaxes.abstractSyntax;

            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x82u;
            transferSyntax.objectIdentifier = value.identification.syntaxes.transferSyntax;

            identificationValue.type = 0x80u;
            identificationValue.sequence = [ abstractSyntax, transferSyntax ];
        }
        else if (!(value.identification.syntax.isNull))
        {
            identificationValue.type = 0x81u;
            identificationValue.objectIdentifier = value.identification.syntax;
        }
        else if (!(value.identification.contextNegotiation.isNull))
        {
            BERValue presentationContextID = new BERValue();
            presentationContextID.type = 0x80u;
            presentationContextID.integer = value.identification.contextNegotiation.presentationContextID;
            
            BERValue transferSyntax = new BERValue();
            transferSyntax.type = 0x81u;
            transferSyntax.objectIdentifier = value.identification.contextNegotiation.transferSyntax;
            
            identificationValue.type = 0x83u;
            identificationValue.sequence = [ presentationContextID, transferSyntax ];
        }
        else if (!(value.identification.transferSyntax.isNull))
        {
            identificationValue.type = 0x84u;
            identificationValue.objectIdentifier = value.identification.transferSyntax;
        }
        else if (value.identification.fixed)
        {
            identificationValue.type = 0x85u;
            identificationValue.nill = [];
        }
        else // it must be the presentationContextID INTEGER
        {
            identificationValue.type = 0x82u;
            identificationValue.integer = value.identification.presentationContextID;
        }

        // This makes identification: [CONTEXT 0][L][CONTEXT #][L][V]
        identification.value = cast(ubyte[]) identificationValue;

        BERValue stringValue = new BERValue();
        stringValue.type = 0x81u;
        stringValue.octetString = value.stringValue;

        this.sequence = [ identification, stringValue ];
    }

    ///
    @system
    unittest
    {
        ASN1ContextSwitchingTypeID id = ASN1ContextSwitchingTypeID();
        id.presentationContextID = 63L;

        CharacterString cs = CharacterString();
        cs.identification = id;
        cs.stringValue = [ 'H', 'E', 'N', 'L', 'O' ];

        BERValue bv = new BERValue();
        bv.characterString = cs;

        CharacterString cs2 = bv.characterString;
        assert(cs2.identification.presentationContextID == 63L);
        assert(cs2.stringValue == [ 'H', 'E', 'N', 'L', 'O' ]);
    }

    // BMPString
    // REVIEW: Does UTF-16 endianness matter? NOTE: PyASN1 encodes this big-endian..
    override public @property
    wstring bmpString()
    {
        version (BigEndian)
        {
            return cast(wstring) this.value;
        }
        version (LittleEndian)
        {
            if (this.value.length % 2)
                throw new BERException
                ("Invalid number of bytes for BMPString. Must be a multiple of 4.");

            wstring ret;
            ptrdiff_t i = 0;
            while (i < this.value.length-1)
            {
                ubyte[] character;
                character.length = 2;
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

    override public @property
    void bmpString(wstring value)
    {
        version (BigEndian)
        {
            this.value = cast(ubyte[]) value;
        }
        version (LittleEndian)
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

    ///
    @system
    unittest
    {
        BERValue bv = new BERValue();
        bv.bmpString = "abcd"w;
        assert(bv.bmpString == "abcd"w);
    }

    this()
    {
        this.type = 0x00;
        this.value = [];
    }

    /**
        Decoding looks like:

        BERValue[] result;
        while (bytes.length > 0)
            result ~= new BERValue(bytes);

        Encoding looks like:

        ubyte[] result;
        foreach (bv; bervalues)
        {
            result ~= cast(ubyte[]) bv;
        }
    */
    this(ref ubyte[] bytes)
    {
        import std.string : indexOf;

        if (bytes.length < 2)
            throw new BERException
            ("BER-encoded value terminated prematurely.");
        
        this.type = bytes[0];
        
        // Length
        if (bytes[1] & 0x80)
        {
            if (bytes[1] & 0x7F) // Definite Long or Reserved
            {
                if ((bytes[1] & 0x7F) == 0x7F) // Reserved
                    throw new BERException
                    ("A BER-encoded length byte of 0xFF is reserved.");

                // Definite Long, if it has made it this far

                if ((bytes[1] & 0x7F) > size_t.sizeof)
                    throw new BERException
                    ("BER-encoded value is too big to decode.");

                version (D_LP64)
                {
                    ubyte[] lengthBytes = [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
                }
                else // FIXME: This *assumes* that the computer must be 32-bit!
                {
                    ubyte[] lengthBytes = [ 0x00, 0x00, 0x00, 0x00 ];
                }
                
                version (LittleEndian)
                {
                    for (ubyte i = (bytes[1] & 0x7F); i > 0; i--)
                    {
                        lengthBytes[i] = bytes[2+i];
                    }
                }
                version (BigEndian)
                {
                    for (ubyte i = 0; i < (bytes[1] & 0x7F); i++)
                    {
                        lengthBytes[i] = bytes[2+i];
                    }
                }

                size_t length = *cast(size_t *) lengthBytes.ptr;
                this.value = bytes[2 .. 3+length];
            }
            else // Indefinite
            {
                // immutable ptrdiff_t indexOfEndOfContent = bytes.indexOf([ 0x00u, 0x00u ]);
                
                size_t indexOfEndOfContent = 0u;
                for (size_t i = 2u; i < bytes.length-1; i++)
                {
                    if ((bytes[i] == 0x00) && (bytes[i+1] == 0x00))
                        indexOfEndOfContent = i;
                }

                if (indexOfEndOfContent == 0u)
                    throw new BERException
                    ("No end-of-content word [0x00,0x00] found at the end of indefinite-length encoded BERValue.");

                this.value = bytes[2 .. indexOfEndOfContent];
            }
        }
        else // Definite Short
        {
            ubyte length = (bytes[1] & 0x7F);

            if (length > (bytes.length-2))
                throw new BERException
                ("BER-encoded value terminated prematurely.");

            this.value = bytes[2 .. 2+length].dup;
            bytes = bytes[2+length .. $];
        }
    }

    // REVIEW: Is this necessary?
    public @property
    ubyte[] toBytes()
    {
        ubyte[] lengthOctets = [ 0x00u ];
        switch (this.longLengthEncodingPreference)
        {
            case (LLEP.definite):
            {
                if (this.length < 127)
                {
                    lengthOctets = [ cast(ubyte) this.length ];    
                }
                else
                {
                    // FIXME: Endianness!
                    size_t length = this.value.length;
                    lengthOctets = [ cast(ubyte) 0x88u ] ~ cast(ubyte[]) *cast(ubyte[4] *) &length;
                }
                break;
            }
            case (LLEP.indefinite):
            {
                lengthOctets = [ 0x80 ];
                break;
            }
            default:
            {
                assert(0, "Invalid LongLengthEncodingPreference encountered!");
            }
        }
        return (
            [ this.type ] ~ 
            lengthOctets ~ 
            this.value ~ 
            (this.longLengthEncodingPreference == LLEP.indefinite ? cast(ubyte[]) [ 0x00, 0x00 ] : cast(ubyte[]) [])
        );
    }

    public
    ubyte[] opCast(T = ubyte[])()
    {
        ubyte[] lengthOctets = [ 0x00u ];
        switch (this.longLengthEncodingPreference)
        {
            case (LLEP.definite):
            {
                if (this.length < 127)
                {
                    lengthOctets = [ cast(ubyte) this.length ];    
                }
                else
                {
                    // FIXME: Endianness!
                    size_t length = this.value.length;
                    lengthOctets = [ cast(ubyte) 0x88u ] ~ cast(ubyte[]) *cast(ubyte[4] *) &length;
                }
                break;
            }
            case (LLEP.indefinite):
            {
                lengthOctets = [ 0x80 ];
                break;
            }
            default:
            {
                assert(0, "Invalid LongLengthEncodingPreference encountered!");
            }
        }
        return (
            [ this.type ] ~ 
            lengthOctets ~ 
            this.value ~ 
            (this.longLengthEncodingPreference == LLEP.indefinite ? cast(ubyte[]) [ 0x00, 0x00 ] : cast(ubyte[]) [])
        );
    }

}

/*
    Tests of all types using definite-short encoding.
*/
@system
unittest
{
    // Test data
    ubyte[] dataEndOfContent = [ 0x00, 0x00 ];
    ubyte[] dataBoolean = [ 0x01, 0x01, 0xFF ];
    ubyte[] dataInteger = [ 0x02, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF ];
    ubyte[] dataBitString = [ 0x03, 0x03, 0x03, 0xF0, 0xF0 ];
    ubyte[] dataOctetString = [ 0x04, 0x04, 0xFF, 0x00, 0x88, 0x14 ];
    ubyte[] dataNull = [ 0x05, 0x00 ];
    ubyte[] dataOID = [ 0x06, 0x04, 0x2B, 0x06, 0x04, 0x01 ];
    ubyte[] dataOD = [ 0x07, 0x05, 'H', 'N', 'E', 'L', 'O' ];
    ubyte[] dataExternal = [ 0x08, 0x1C, 0x80, 0x0A, 0x81, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1B, 0x81, 0x08, 0x65, 0x78, 0x74, 0x65, 0x72, 0x6E, 0x61, 0x6C, 0x82, 0x04, 0x01, 0x02, 0x03, 0x04 ];
    ubyte[] dataReal = [ 0x09, 0x03, 0x80, 0xFB, 0x05 ]; // 0.15625 (From StackOverflow question)
    ubyte[] dataEnum = [ 0x0A, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF ];
    ubyte[] dataEmbeddedPDV = [ 0x0B, 0x1C, 0x80, 0x0A, 0x82, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1B, 0x81, 0x08, 0x41, 0x41, 0x41, 0x41, 0x42, 0x42, 0x42, 0x42, 0x82, 0x04, 0x01, 0x02, 0x03, 0x04 ];
    ubyte[] dataUTF8 = [ 0x0C, 0x05, 'H', 'E', 'N', 'L', 'O' ];
    ubyte[] dataROID = [ 0x0D, 0x03, 0x06, 0x04, 0x01 ];
    // sequence
    // set
    ubyte[] dataNumeric = [ 0x12, 0x07, '8', '6', '7', '5', '3', '0', '9' ];
    ubyte[] dataPrintable = [ 0x13, 0x08, '8', '6', ' ', 'b', '&', '~', 'f', '8' ];
    ubyte[] dataTeletex = [ 0x14, 0x06, 0xFF, 0x05, 0x04, 0x03, 0x02, 0x01 ];
    ubyte[] dataVideotex = [ 0x15, 0x06, 0xFF, 0x05, 0x04, 0x03, 0x02, 0x01 ];
    ubyte[] dataIA5 = [ 0x16, 0x08, 'B', 'O', 'R', 'T', 'H', 'E', 'R', 'S' ];
    ubyte[] dataUTC = [ 0x17, 0x0C, '1', '7', '0', '8', '3', '1', '1', '3', '4', '5', '0', '0' ];
    ubyte[] dataGT = [ 0x18, 0x0E, '2', '0', '1', '7', '0', '8', '3', '1', '1', '3', '4', '5', '0', '0' ];
    ubyte[] dataGraphic = [ 0x19, 0x0B, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    ubyte[] dataVisible = [ 0x1A, 0x0B, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    ubyte[] dataGeneral = [ 0x1B, 0x0B, 'P', 'o', 'w', 'e', 'r', 'T', 'h', 'i', 'r', 's', 't' ];
    ubyte[] dataUniversal = [ 0x1C, 0x10, 0x00, 0x00, 0x00, 0x61, 0x00, 0x00, 0x00, 0x62, 0x00, 0x00, 0x00, 0x63, 0x00, 0x00, 0x00, 0x64 ]; // Big-endian "abcd"
    ubyte[] dataCharacter = [ 0x1D, 0x13, 0x80, 0x0A, 0x82, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3F, 0x81, 0x05, 0x48, 0x45, 0x4E, 0x4C, 0x4F ];
    ubyte[] dataBMP = [ 0x1E, 0x08, 0x00, 0x61, 0x00, 0x62, 0x00, 0x63, 0x00, 0x64 ]; // Big-endian "abcd"

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

    BERValue[] result;
    while (data.length > 0)
        result ~= new BERValue(data);

    // Ensure use of accessors does not mutate state.
    assert(result[1].boolean == result[1].boolean);
    assert(result[2].integer == result[2].integer);
    assert(cast(size_t[]) result[3].bitString == cast(size_t[]) result[3].bitString); // Not my fault that std.bitmanip.BitArray is fucking stupid.
    assert(result[4].octetString == result[4].octetString);
    assert(result[5].nill.length == result[5].nill.length);
    assert(result[6].objectIdentifier.numericArray == result[6].objectIdentifier.numericArray);
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert(result[8].external == result[8].external);
    assert(result[9].realType!float == result[9].realType!float);
    assert(result[10].enumerated == result[10].enumerated);
    assert(result[11].embeddedPDV == result[11].embeddedPDV);
    assert(result[12].utf8string == result[12].utf8string);
    assert(result[13].relativeObjectIdentifier.numericArray == result[13].relativeObjectIdentifier.numericArray);
    assert(result[14].numericString == result[14].numericString);
    assert(result[15].printableString == result[15].printableString);
    assert(result[16].teletexString == result[16].teletexString);
    assert(result[17].videotexString == result[17].videotexString);
    assert(result[18].ia5String == result[18].ia5String);
    assert(result[19].utcTime == result[19].utcTime);
    assert(result[20].generalizedTime == result[20].generalizedTime);
    assert(result[21].graphicString == result[21].graphicString);
    assert(result[22].visibleString == result[22].visibleString);
    assert(result[23].generalString == result[23].generalString);
    assert(result[24].universalString == result[24].universalString);
    assert(result[25].characterString == result[25].characterString);
    assert(result[26].bmpString == result[26].bmpString);

    // Pre-processing
    External x = result[8].external;
    EmbeddedPDV m = result[11].embeddedPDV;
    CharacterString c = result[25].characterString;

    // Ensure accessors decode the data correctly.
    assert(result[1].boolean == true);
    assert(result[2].integer == 255L);
    // assert(cast(void[]) result[3].bitString == cast(void[]) BitArray([0xF0, 0xF0], 13));
    // NOTE: I think std.bitmanip.BitArray.opCast(void[]) is broken...
    assert(result[4].octetString == [ 0xFF, 0x00, 0x88, 0x14 ]);
    assert(result[5].nill == []);
    assert(result[6].objectIdentifier.numericArray == (new OID(0x01u, 0x03u, 0x06u, 0x04u, 0x01u)).numericArray);
    assert(result[7].objectDescriptor == result[7].objectDescriptor);
    assert((x.identification.presentationContextID == 27L) && (x.dataValue == [ 0x01, 0x02, 0x03, 0x04 ]));
    assert(result[9].realType!float == 0.15625);
    assert(result[9].realType!double == 0.15625);
    assert(result[10].enumerated == 255L);
    assert((x.identification.presentationContextID == 27L) && (x.dataValue == [ 0x01, 0x02, 0x03, 0x04 ]));
    assert(result[12].utf8string == "HENLO");
    assert(result[13].relativeObjectIdentifier.numericArray == (new ROID(0x06u, 0x04u, 0x01u)).numericArray);
    assert(result[14].numericString == "8675309");
    assert(result[15].printableString ==  "86 b&~f8");
    assert(result[16].teletexString == [ 0xFF, 0x05, 0x04, 0x03, 0x02, 0x01 ]);
    assert(result[17].videotexString == [ 0xFF, 0x05, 0x04, 0x03, 0x02, 0x01 ]);
    assert(result[18].ia5String == "BORTHERS");
    assert(result[19].utcTime == DateTime(2017, 8, 31, 13, 45));
    assert(result[20].generalizedTime == DateTime(2017, 8, 31, 13, 45));
    assert(result[21].graphicString == "PowerThirst");
    assert(result[22].visibleString == "PowerThirst");
    assert(result[23].generalString == "PowerThirst");
    assert(result[24].universalString == "abcd"d);
    assert((c.identification.presentationContextID == 63L) && (c.stringValue == "HENLO"w));
}