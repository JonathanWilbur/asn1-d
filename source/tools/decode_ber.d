module asn1.tools.decode_ber;
import asn1.codecs.ber;
import asn1.tools.decoder_mixin : Decoder;
mixin Decoder!BERElement;