/* 
    This just tests all possible four byte combinations for RangeErrors

    Build like so:

    dmd ./source/asn1.d ./source/codec.d ./source/interfaces.d ./source/types/*.d ./source/types/universal/*.d ./source/codecs/*.d ./test/fuzz/fourbytes.d -d -of./build/binaries/fourbytes
*/
import codecs.ber;
import codecs.cer;
import codecs.der;
import core.exception : RangeError;
import std.stdio : writefln, writeln;

void main()
{
    for (uint x = 0u; x < uint.max; x++)
    {
        ubyte[] testBytes;
        testBytes.length = uint.sizeof;
        *cast(uint *)&testBytes[0] = x;
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