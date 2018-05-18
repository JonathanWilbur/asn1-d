// D import file generated from '.\source\asn1\codecs\cer.d'
module asn1.codecs.cer;
public import asn1.codec;
public import asn1.interfaces : Byteable;
public import asn1.types.identification;
public alias cerOID = canonicalEncodingRulesObjectIdentifier;
public alias cerObjectID = canonicalEncodingRulesObjectIdentifier;
public alias cerObjectIdentifier = canonicalEncodingRulesObjectIdentifier;
public immutable OID canonicalEncodingRulesObjectIdentifier = cast(immutable(OID))new OID(2, 1, 2, 0);
public alias CERElement = CanonicalEncodingRulesElement;
public class CanonicalEncodingRulesElement : ASN1Element!CERElement, Byteable
{
	public override const @property @safe void endOfContent();
	public override const @property @safe bool boolean();
	public override nothrow @property @safe void boolean(in bool value);
	public const @property @system T integer(T)() if (isIntegral!T && isSigned!T || is(T == BigInt))
	{
		if (this.construction != ASN1Construction.primitive)
			throw new ASN1ConstructionException(this.construction, "decode an INTEGER");
		if (this.value.length == 1u)
		{
			static if (is(T == BigInt))
			{
				return BigInt(cast(byte)this.value[0]);
			}
			else
			{
				return cast(T)cast(byte)this.value[0];
			}
		}
		if (this.value.length == 0u)
			throw new ASN1ValueSizeException(1u, (long).sizeof, this.value.length, "decode an INTEGER");
		static if (!is(T == BigInt))
		{
			if (this.value.length > T.sizeof)
				throw new ASN1ValueSizeException(1u, (long).sizeof, this.value.length, "decode an INTEGER");
		}

		if (this.value[0] == 0u && !(this.value[1] & 128u) || this.value[0] == 255u && this.value[1] & 128u)
			throw new ASN1ValuePaddingException("This exception was thrown because you attempted to decode " ~ "an INTEGER that was encoded on more than the minimum " ~ "necessary bytes. " ~ notWhatYouMeantText ~ forMoreInformationText ~ debugInformationText ~ reportBugsText);
		static if (is(T == BigInt))
		{
			BigInt ret = BigInt(0);
			ret += cast(byte)(this.value[0] & 128u);
			ret += this.value[0] & cast(ubyte)127u;
			foreach (immutable ubyte b; this.value[1..$])
			{
				ret <<= 8;
				ret += b;
			}
			return ret;
		}
		else
		{
			immutable ubyte paddingByte = this.value[0] & 128u ? 255u : 0u;
			ubyte[] value = this.value.dup;
			while (value.length < T.sizeof)
			value = paddingByte ~ value;
			version (LittleEndian)
			{
				reverse(value);
			}

			version (unittest)
			{
				assert(value.length == T.sizeof);
			}

			return *cast(T*)value.ptr;
		}
	}
	public @property @system void integer(T)(in T value) if (isIntegral!T && isSigned!T || is(T == BigInt))
	out
	{
		assert(this.value.length > 0u);
	}
	do
	{
		scope(success) this.construction = ASN1Construction.primitive;
		if (value <= (byte).max && (value >= (byte).min))
		{
			this.value = [cast(ubyte)cast(byte)value];
			return ;
		}
		ubyte[] ub;
		static if (is(T == BigInt))
		{
			if (value.uintLength > size_t.max >> 5u)
				throw new ASN1ValueSizeException(1u, size_t.max >> 2u, value.uintLength << 2u, "encode an INTEGER from a BigInt");
			ub.length = value.uintLength * (uint).sizeof + 1u;
			for (size_t i = 0u;
			 i < value.uintLength; i++)
			{
				{
					*cast(uint*)&ub[i << 2u] = cast(uint)(value >> (i << 5u) & (uint).max);
				}
			}
			if (value >= 0)
				ub[$ - 1] = 0u;
			else
				ub[$ - 1] = 255u;
		}
		else
		{
			ub.length = T.sizeof;
			*cast(T*)&ub[0] = value;
		}
		version (LittleEndian)
		{
			reverse(ub);
		}

		size_t startOfNonPadding = 0u;
		static if (T.sizeof > 1u)
		{
			if (value >= 0)
			{
				for (size_t i = 0u;
				 i < ub.length - 1; i++)
				{
					{
						if (ub[i] != 0u)
							break;
						if (!(ub[i + 1] & 128u))
							startOfNonPadding++;
					}
				}
			}
			else
			{
				for (size_t i = 0u;
				 i < ub.length - 1; i++)
				{
					{
						if (ub[i] != 255u)
							break;
						if (ub[i + 1] & 128u)
							startOfNonPadding++;
					}
				}
			}
		}

		this.value = ub[startOfNonPadding..$];
	}
	public override const @property @system bool[] bitString();
	public override @property @system void bitString(in bool[] value);
	public override const @property @system ubyte[] octetString();
	public override @property @system void octetString(in ubyte[] value);
	public override const @property @safe void nill();
	public override const @property @system OID objectIdentifier();
	public override @property @system void objectIdentifier(in OID value);
	public override const @property @system string objectDescriptor();
	public override @property @system void objectDescriptor(in string value);
	public deprecated override const @property @system External external();
	public deprecated override @property @system void external(in External value);
	public const @property @system T realNumber(T)() if (isFloatingPoint!T)
	{
		if (this.construction != ASN1Construction.primitive)
			throw new ASN1ConstructionException(this.construction, "decode a REAL");
		if (this.value.length == 0u)
			return cast(T)0.000000;
		switch (this.value[0] & 192u)
		{
			case 64u:
			{
				{
					if (this.value[0] == ASN1SpecialRealValue.notANumber)
						return T.nan;
					if (this.value[0] == ASN1SpecialRealValue.minusZero)
						return -0.000000;
					if (this.value[0] == ASN1SpecialRealValue.plusInfinity)
						return T.infinity;
					if (this.value[0] == ASN1SpecialRealValue.minusInfinity)
						return -T.infinity;
					throw new ASN1ValueUndefinedException("This exception was thrown because you attempted to decode " ~ "a REAL whose information byte indicated a special value " ~ "not recognized by the specification. The only special " ~ "values recognized by the specification are PLUS-INFINITY, " ~ "MINUS-INFINITY, NOT-A-NUMBER, and minus zero, identified " ~ "by information bytes of 0x40, 0x41 0x42, 0x43 respectively. " ~ notWhatYouMeantText ~ forMoreInformationText ~ debugInformationText ~ reportBugsText);
				}
			}
			case 0u:
			{
				{
					import std.conv : to;
					import std.string : indexOf;
					immutable string invalidNR3RealMessage = "This exception was thrown because you attempted to decode " ~ "a base-10 encoded REAL that was encoded with improper " ~ "format. When using Canonical Encoding Rules (CER) or " ~ "Distinguished Encoding Rules (DER), the base-10 encoded " ~ "REAL must be encoded in the NR3 format specified in " ~ "ISO 6093. Further, there may be no whitespace, no leading " ~ "zeroes, no trailing zeroes on the mantissa, before or " ~ "after the decimal point, and no plus sign should ever " ~ "appear, unless the exponent is 0, in which case, the " ~ "exponent should read '+0'. Further, there must be a " ~ "decimal point, immediately followed by a capital 'E'." ~ "Your problem, in this case, was that your encoded value ";
					if (this.value.length < 5u)
						throw new ASN1ValueSizeException(5u, size_t.max, this.value.length, "decode a base-10 encoded REAL");
					if (this.value[0] != 3u)
						throw new ASN1ValueException(invalidNR3RealMessage ~ "was not NR3 format at all.");
					string valueString = cast(string)this.value[1..$];
					foreach (character; valueString)
					{
						import std.ascii : isWhite;
						if (character.isWhite || character == ',' || character == '_')
							throw new ASN1ValueCharactersException("1234567890+-.E", character, "decode a base-10 encoded REAL");
					}
					if (valueString[0] == '0' || valueString[0] == '-' && (valueString[1] == '0'))
						throw new ASN1ValuePaddingException(invalidNR3RealMessage ~ "contained a leading zero.");
					ptrdiff_t indexOfDecimalPoint = valueString.indexOf(".");
					if (indexOfDecimalPoint == -1)
						throw new ASN1ValueException(invalidNR3RealMessage ~ "contained no decimal point.");
					if (valueString[indexOfDecimalPoint + 1] != 'E')
						throw new ASN1ValueException(invalidNR3RealMessage ~ "contained no 'E'.");
					if (valueString[indexOfDecimalPoint - 1] == '0')
						throw new ASN1ValuePaddingException(invalidNR3RealMessage ~ "contained a trailing zero on the mantissa.");
					if (valueString[$ - 2..$] != "+0" && canFind(valueString, '+'))
						throw new ASN1ValueException(invalidNR3RealMessage ~ "contained an illegitimate plus sign.");
					if (canFind(valueString, "E0") || canFind(valueString, "E-0"))
						throw new ASN1ValuePaddingException(invalidNR3RealMessage ~ "contained a leading zero on the exponent.");
					return to!T(valueString);
				}
			}
			case 128u:
			case 192u:
			{
				{
					ulong mantissa;
					short exponent;
					ubyte scale;
					ubyte base;
					size_t startOfMantissa;
					switch (this.value[0] & 3u)
					{
						case 0u:
						{
							{
								if (this.value.length < 3u)
									throw new ASN1TruncationException(3u, this.value.length, "decode a REAL exponent");
								exponent = cast(short)cast(byte)this.value[1];
								startOfMantissa = 2u;
								break;
							}
						}
						case 1u:
						{
							{
								if (this.value.length < 4u)
									throw new ASN1TruncationException(4u, this.value.length, "decode a REAL exponent");
								ubyte[] exponentBytes = this.value[1..3].dup;
								version (LittleEndian)
								{
									exponentBytes = [exponentBytes[1], exponentBytes[0]];
								}

								exponent = *cast(short*)exponentBytes.ptr;
								if (exponent <= (byte).max && (exponent >= (byte).min))
									throw new ASN1ValuePaddingException("This exception was thrown because you attempted " ~ "to decode a binary-encoded REAL whose exponent " ~ "was encoded on more bytes than necessary. This " ~ "would not be a problem if you were using the " ~ "Basic Encoding Rules (BER), but the Canonical " ~ "Encoding Rules (CER) and Distinguished Encoding " ~ "Rules (DER) require that the exponent be " ~ "encoded on the fewest possible bytes. " ~ notWhatYouMeantText ~ forMoreInformationText ~ debugInformationText ~ reportBugsText);
								startOfMantissa = 3u;
								break;
							}
						}
						case 2u:
						{
						}
						case 3u:
						{
							{
								throw new ASN1ValueOverflowException("This exception was thrown because, according to " ~ "section 11.3.1 of specification X.690, a REAL's " ~ "exponent must be encoded on the fewest possible " ~ "octets, but you attempted to decode one that was " ~ "either too big to fit in an IEEE 754 floating " ~ "point type, or would have had unnecessary leading " ~ "bytes if it could. ");
							}
						}
						default:
						{
							assert(0, "Impossible binary exponent encoding on REAL type");
						}
					}
					if (this.value.length - startOfMantissa > (ulong).sizeof)
						throw new ASN1ValueOverflowException("This exception was thrown because you attempted to " ~ "decode a REAL whose mantissa was encoded on too many " ~ "bytes to decode to the largest unsigned integral data " ~ "type. ");
					ubyte[] mantissaBytes = this.value[startOfMantissa..$].dup;
					if (mantissaBytes[0] == 0u)
						throw new ASN1ValuePaddingException("This exception was thrown because you attempted to decode " ~ "a REAL mantissa that was encoded on more than the minimum " ~ "necessary bytes. " ~ notWhatYouMeantText ~ forMoreInformationText ~ debugInformationText ~ reportBugsText);
					while (mantissaBytes.length < (ulong).sizeof)
					mantissaBytes = 0u ~ mantissaBytes;
					version (LittleEndian)
					{
						reverse(mantissaBytes);
					}

					version (unittest)
					{
						assert(mantissaBytes.length == (ulong).sizeof);
					}

					mantissa = *cast(ulong*)mantissaBytes.ptr;
					if (mantissa == 0u)
						throw new ASN1ValueException("This exception was thrown because you attempted to " ~ "decode a REAL that was encoded on more than zero " ~ "bytes, but whose mantissa encoded a zero. This " ~ "is prohibited by specification X.690. If the " ~ "abstract value encoded is a real number of zero, " ~ "the REAL must be encoded upon zero bytes. " ~ notWhatYouMeantText ~ forMoreInformationText ~ debugInformationText ~ reportBugsText);
					switch (this.value[0] & 48u)
					{
						case 0u:
						{
							{
								if (!(mantissa & 1u))
									throw new ASN1ValueException("This exception was thrown because you attempted to " ~ "decode a base-2 encoded REAL whose mantissa was " ~ "not zero or odd. Both Canonical Encoding Rules (CER) " ~ "and Distinguished Encoding Rules (DER) require that " ~ "a base-2 encoded REAL's mantissa be shifted so that " ~ "it is either zero or odd. ");
								base = 2u;
								break;
							}
						}
						case 16u:
						{
							base = 8u;
							break;
						}
						case 32u:
						{
							base = 16u;
							break;
						}
						default:
						{
							throw new ASN1ValueUndefinedException("This exception was thrown because you attempted to " ~ "decode a REAL that had both base bits in the " ~ "information block set, the meaning of which is " ~ "not specified. " ~ notWhatYouMeantText ~ forMoreInformationText ~ debugInformationText ~ reportBugsText);
						}
					}
					if (this.value[0] & 12u)
						throw new ASN1ValueException("This exception was thrown because you attempted to " ~ "decode a REAL whose scale was not zero. This would " ~ "not be a problem if you were using the Basic " ~ "Encoding Rules (BER), but specification X.690 " ~ "says that, when using the Canonical Encoding Rules " ~ "(CER) or Distinguished Encoding Rules (DER), the " ~ "scale must be zero. " ~ notWhatYouMeantText ~ forMoreInformationText ~ debugInformationText ~ reportBugsText);
					return (this.value[0] & 64u ? -1.00000 : 1.00000) * cast(T)mantissa * 2 ^^ scale * cast(T)base ^^ cast(T)exponent;
				}
			}
			default:
			{
				assert(0, "Impossible information byte value appeared!");
			}
		}
	}
	public nothrow @property @system void realNumber(T)(in T value) if (isFloatingPoint!T)
	{
		scope(success) this.construction = ASN1Construction.primitive;
		if (isIdentical(value, 0.000000))
		{
			this.value = [];
			return ;
		}
		else if (isIdentical(value, -0.000000))
		{
			this.value = [ASN1SpecialRealValue.minusZero];
			return ;
		}
		else if (value.isNaN)
		{
			this.value = [ASN1SpecialRealValue.notANumber];
			return ;
		}
		else if (value == T.infinity)
		{
			this.value = [ASN1SpecialRealValue.plusInfinity];
			return ;
		}
		else if (value == -T.infinity)
		{
			this.value = [ASN1SpecialRealValue.minusInfinity];
			return ;
		}
		real realValue = cast(real)value;
		bool positive = true;
		ulong mantissa;
		short exponent;
		ubyte[] realBytes;
		realBytes.length = (real).sizeof;
		*cast(real*)&realBytes[0] = realValue;
		version (BigEndian)
		{
			static if ((real).sizeof > 10u)
			{
				realBytes = realBytes[(real).sizeof - 10..$];
			}

			positive = realBytes[0] & 128u ? false : true;
		}
		else
		{
			version (LittleEndian)
			{
				static if ((real).sizeof > 10u)
				{
					realBytes.length = 10u;
				}

				positive = realBytes[$ - 1] & 128u ? false : true;
			}
			else
			{
				assert(0, "Could not determine endianness");
			}
		}
		static if ((real).mant_dig == 64)
		{
			version (BigEndian)
			{
				exponent = (*cast(short*)&realBytes[0] & 32767) - 16383 - 63;
				mantissa = *cast(ulong*)&realBytes[2];
			}
			else
			{
				version (LittleEndian)
				{
					exponent = (*cast(short*)&realBytes[8] & 32767) - 16383 - 63;
					mantissa = *cast(ulong*)&realBytes[0];
				}
				else
				{
					assert(0, "Could not determine endianness");
				}
			}
		}
		else
		{
			if (T.mant_dig == 53)
			{
				version (BigEndian)
				{
					exponent = (*cast(short*)&realBytes[0] & 32767) - 1023 - 53;
					mantissa = *cast(ulong*)&realBytes[2] & 4503599627370495LU | 4503599627370496LU;
				}
				else
				{
					version (LittleEndian)
					{
						exponent = (*cast(short*)&realBytes[8] & 32767) - 1023 - 53;
						mantissa = *cast(ulong*)&realBytes[0] & 4503599627370495LU | 4503599627370496LU;
					}
					else
					{
						assert(0, "Could not determine endianness");
					}
				}
			}
			else if (T.mant_dig == 24)
			{
				version (BigEndian)
				{
					exponent = ((*cast(short*)&realBytes[0] & 32640) >> 7) - 127 - 23;
					mantissa = cast(ulong)(*cast(uint*)&realBytes[2] & 8388607u | 8388608u);
				}
				else
				{
					version (LittleEndian)
					{
						exponent = ((*cast(short*)&realBytes[8] & 32640) >> 7) - 127 - 23;
						mantissa = cast(ulong)(*cast(uint*)&realBytes[0] & 8388607u | 8388608u);
					}
					else
					{
						assert(0, "Could not determine endianness");
					}
				}
			}
			else
				assert(0, "Unrecognized real floating-point format.");
		}
		if (mantissa != 0u)
		{
			while (!(mantissa & 1u))
			{
				mantissa >>= 1;
				exponent++;
			}
			version (unittest)
			{
				assert(mantissa & 1u);
			}

		}
		ubyte[] exponentBytes;
		exponentBytes.length = (short).sizeof;
		*cast(short*)exponentBytes.ptr = exponent;
		version (LittleEndian)
		{
			exponentBytes = [exponentBytes[1], exponentBytes[0]];
		}

		if (exponentBytes[0] == 0u && !(exponentBytes[1] & 128u) || exponentBytes[0] == 255u && exponentBytes[1] & 128u)
			exponentBytes = exponentBytes[1..2];
		ubyte[] mantissaBytes;
		mantissaBytes.length = (ulong).sizeof;
		*cast(ulong*)mantissaBytes.ptr = cast(ulong)mantissa;
		version (LittleEndian)
		{
			reverse(mantissaBytes);
		}

		size_t startOfNonPadding = 0u;
		for (size_t i = 0u;
		 i < mantissaBytes.length - 1; i++)
		{
			{
				if (mantissaBytes[i] != 0u)
					break;
				startOfNonPadding++;
			}
		}
		mantissaBytes = mantissaBytes[startOfNonPadding..$];
		ubyte infoByte = 128u | (positive ? 0u : 64u) | cast(ubyte)(exponentBytes.length == 1u ? ASN1RealExponentEncoding.followingOctet : ASN1RealExponentEncoding.following2Octets);
		this.value = infoByte ~ exponentBytes ~ mantissaBytes;
	}
	public const @property @system T enumerated(T)() if (isIntegral!T && isSigned!T)
	{
		if (this.construction != ASN1Construction.primitive)
			throw new ASN1ConstructionException(this.construction, "decode an ENUMERATED");
		if (this.value.length == 1u)
			return cast(T)cast(byte)this.value[0];
		if (this.value.length == 0u || this.value.length > T.sizeof)
			throw new ASN1ValueSizeException(1u, (long).sizeof, this.value.length, "decode an ENUMERATED");
		if (this.value[0] == 0u && !(this.value[1] & 128u) || this.value[0] == 255u && this.value[1] & 128u)
			throw new ASN1ValueException("This exception was thrown because you attempted to decode " ~ "an ENUMERATED that was encoded on more than the minimum " ~ "necessary bytes. " ~ notWhatYouMeantText ~ forMoreInformationText ~ debugInformationText ~ reportBugsText);
		immutable ubyte paddingByte = this.value[0] & 128u ? 255u : 0u;
		ubyte[] value = this.value.dup;
		while (value.length < T.sizeof)
		value = paddingByte ~ value;
		version (LittleEndian)
		{
			reverse(value);
		}

		version (unittest)
		{
			assert(value.length == T.sizeof);
		}

		return *cast(T*)value.ptr;
	}
	public nothrow @property @system void enumerated(T)(in T value)
	out
	{
		assert(this.value.length > 0u);
	}
	do
	{
		scope(success) this.construction = ASN1Construction.primitive;
		if (value <= (byte).max && (value >= (byte).min))
		{
			this.value = [cast(ubyte)cast(byte)value];
			return ;
		}
		ubyte[] ub;
		ub.length = T.sizeof;
		*cast(T*)&ub[0] = value;
		version (LittleEndian)
		{
			reverse(ub);
		}

		size_t startOfNonPadding = 0u;
		if (T.sizeof > 1u)
		{
			if (value >= 0)
			{
				for (size_t i = 0u;
				 i < ub.length - 1; i++)
				{
					{
						if (ub[i] != 0u)
							break;
						if (!(ub[i + 1] & 128u))
							startOfNonPadding++;
					}
				}
			}
			else
			{
				for (size_t i = 0u;
				 i < ub.length - 1; i++)
				{
					{
						if (ub[i] != 255u)
							break;
						if (ub[i + 1] & 128u)
							startOfNonPadding++;
					}
				}
			}
		}
		this.value = ub[startOfNonPadding..$];
	}
	public override const @property @system EmbeddedPDV embeddedPresentationDataValue();
	public override @property @system void embeddedPresentationDataValue(in EmbeddedPDV value);
	public override const @property @system string unicodeTransformationFormat8String();
	public override @property @system void unicodeTransformationFormat8String(in string value);
	public override const @property @system OIDNode[] relativeObjectIdentifier();
	public override nothrow @property @system void relativeObjectIdentifier(in OIDNode[] value);
	public override const @property @system CERElement[] sequence();
	public override @property @system void sequence(in CERElement[] value);
	public override const @property @system CERElement[] set();
	public override @property @system void set(in CERElement[] value);
	public override const @property @system string numericString();
	public override @property @system void numericString(in string value);
	public override const @property @system string printableString();
	public override @property @system void printableString(in string value);
	public override const @property @system ubyte[] teletexString();
	public override @property @system void teletexString(in ubyte[] value);
	public override const @property @system ubyte[] videotexString();
	public override @property @system void videotexString(in ubyte[] value);
	public override const @property @system string internationalAlphabetNumber5String();
	public override @property @system void internationalAlphabetNumber5String(in string value);
	public override const @property @system DateTime coordinatedUniversalTime();
	public override @property @system void coordinatedUniversalTime(in DateTime value);
	public override const @property @system DateTime generalizedTime();
	public override @property @system void generalizedTime(in DateTime value);
	public override const @property @system string graphicString();
	public override @property @system void graphicString(in string value);
	public override const @property @system string visibleString();
	public override @property @system void visibleString(in string value);
	public override const @property @system string generalString();
	public override @property @system void generalString(in string value);
	public override const @property @system dstring universalString();
	public override @property @system void universalString(in dstring value);
	public override const @property @system CharacterString characterString();
	public override @property @system void characterString(in CharacterString value);
	public override const @property @system wstring basicMultilingualPlaneString();
	public override @property @system void basicMultilingualPlaneString(in wstring value);
	public nothrow @nogc @safe this(ASN1TagClass tagClass = ASN1TagClass.universal, ASN1Construction construction = ASN1Construction.primitive, size_t tagNumber = 0u)
	{
		this.tagClass = tagClass;
		this.construction = construction;
		this.tagNumber = tagNumber;
		this.value = [];
	}
	public @system this(ref ubyte[] bytes)
	{
		size_t bytesRead = this.fromBytes(bytes);
		bytes = bytes[bytesRead..$];
	}
	public @system this(in ubyte[] bytes)
	{
		immutable size_t bytesRead = this.fromBytes(bytes);
		if (bytesRead != bytes.length)
			throw new ASN1LengthException("This exception was thrown because you attempted to decode " ~ "a single ASN.1 element that was encoded on too many bytes. " ~ "The entire element was decoded from " ~ text(bytesRead) ~ " " ~ "bytes, but " ~ text(bytes.length) ~ " bytes were supplied to " ~ "decode.");
	}
	public @system this(ref size_t bytesRead, in ubyte[] bytes)
	{
		bytesRead += this.fromBytes(bytes[bytesRead..$].dup);
	}
	public size_t fromBytes(in ubyte[] bytes);
	public const nothrow @property @system ubyte[] toBytes();
	public nothrow @system ubyte[] opCast(T = ubyte[])()
	{
		return this.toBytes();
	}
}
