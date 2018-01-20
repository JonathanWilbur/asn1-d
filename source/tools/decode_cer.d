module asn1.tools.decode_cer;
import asn1.codecs.cer;
import asn1.tools.decoder_mixin : Decoder;
mixin Decoder!CERElement;