/*
    This just tests all possible two byte combinations for RangeErrors

    Build like so:

    dmd ./source/asn1/constants.d ./source/asn1/codec.d ./source/asn1/interfaces.d ./source/asn1/types/*.d ./source/asn1/types/universal/*.d ./source/asn1/codecs/*.d ./test/fuzz/twobytes.d -d -of./build/executables/twobytes
*/
import asn1.codecs.ber;
import asn1.codecs.cer;
import asn1.codecs.der;
import core.exception : RangeError;
import std.stdio : writefln, writeln;

void main()
{
    for (ushort x = 0u; x < ushort.max; x++)
    {
        ubyte[] testBytes;
        testBytes.length = ushort.sizeof;
        *cast(ushort *)&testBytes[0] = x;
        writefln("%(%02X %)", testBytes);

        size_t bytesRead;
        try
        {
            bytesRead = 0u;
            new BERElement(bytesRead, testBytes);
            bytesRead = 0u;
            new CERElement(bytesRead, testBytes);
            bytesRead = 0u;
            new DERElement(bytesRead, testBytes);
        }
        catch (Exception e)
        {
            continue;
        }
        catch (RangeError e)
        {
            writefln("RANGE ERROR CAUGHT! This was the encoded data: %(%02X %)", testBytes);
            break;
        }
    }
}