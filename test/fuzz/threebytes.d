/*
    This just tests all possible three byte combinations for RangeErrors

    Build like so:

    dmd ./source/asn1.d ./source/codec.d ./source/interfaces.d ./source/types/*.d ./source/types/universal/*.d ./source/codecs/*.d ./test/fuzz/threebytes.d -d -of./build/executables/threebytes
*/
import codecs.ber;
import codecs.cer;
import codecs.der;
import core.exception : RangeError;
import std.stdio : writefln, writeln;

void main()
{
    for (ubyte x = 0x00u; x < ubyte.max; x++)
    {
        for (ubyte y = 0x00u; y < ubyte.max; y++)
        {
            for (ubyte z = 0x00u; z < ubyte.max; z++)
            {
                ubyte[] testBytes = [ x, y, z ];
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
    }
}