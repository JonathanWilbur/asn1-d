module conv;

immutable private string hexDigits = "0123456789ABCDEF";

pragma(inline, true):
private
string byteToHex(ubyte value)
{
    return [hexDigits[((value & 0xF0) >> 4)], hexDigits[(value & 0x0F)]];
}

/*
    NOTE: This does not actually check that the input string is two characters,
    but it is only for private use, so it just asserts(0) if you provide more
    than two characters.
*/
pragma(inline, true):
private
ubyte hexToByte(string value)
{
    assert(value.length == 2, "hexToByte() received a non hex-pair input.");
    ubyte ret = 0x00;
    for (int i = 0; i < 16; i++)
    {
        if (value[0] == hexDigits[i]) ret |= cast(ubyte) (i << 4);
        if (value[1] == hexDigits[i]) ret |= cast(ubyte) (i);
    }
    return ret;
}

pragma(inline, true):
private
bool isHexDigit(char c)
{
    /*
        FIXME: You can improve the performance of this by testing if each char
        is between (inclusive) 0x30 - 0x39, 0x41 - 0x46, or 0x61 - 0x66 instead
        of testing all sixteen characters.
    */
    for (int i; i < 16; i++) if (c == hexDigits[i]) return true;
    return false;
}

pragma(inline, true):
private
ubyte[] hexToBytes(string hex)
{
    ubyte[] bytes;
    for (int i = 0; i < hex.length-1; i++)
    {
        if (!isHexDigit(hex[i]) || !isHexDigit(hex[i+1])) continue;
        bytes ~= hexToByte([hex[i], hex[i+1]]);
    }
    return bytes;
}