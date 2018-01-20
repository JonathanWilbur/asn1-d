module asn1.tools.encode_ber;
import asn1.codecs.ber;
import asn1.tools.encoder_mixin : Encoder;
mixin Encoder!BERElement;