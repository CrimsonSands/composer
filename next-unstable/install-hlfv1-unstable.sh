ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1-unstable.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1-unstable.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data-unstable"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:unstable
docker tag hyperledger/composer-playground:unstable hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv11/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �y8Z �=KlIv�lv��A�'3�X��R��dw�'ң��I�L��(ydǫivɖ�������^�%�I	0� � �9�l� 2��r�%A�yU�$�eɶ,g`0f���{�^�_}�G5�lG�k��X�<hۦg��AW�t>���J%�o<-��_Z�B���N���K����%ğ���qe�K�-j��p��C�!��4��x��lj
v����v��_�+k������Vڨu�6�u�u����T��Z��:%Bt}�_��뜁ݞi�V�dOw ��6d}�m��=�{Ӳ�&��ܴ5%����|Іع� 6�N'O�(#�O���'�T�J�;'3�[n�3��]��Q�s4��'O���@�_�I1.�)��Ӊ������Q�����t8��l������G�l�k��iN�Z���ܮ狏�����f]����
O�=ݔUl��p�b�T_y	$ܢau�f���:�D,��>����AV�����M-3��Ų��=C���_��b�"��"���!Oya��]L	�?������g(.$����.:��eCE6*1�=�Ќ�8)t�Q'�5�7��WV�n�T���ȓ���B���V0��VP8��!(H���1Qx���	�F��)����O�I��(P>)f��qq���.�H�N9$�vQ�(�"t�)��h�F�d��a@1��2�����?���錳~�cX#fVM���|`��1s�0]�&��ǩ>b�Ց����7gX��7�4�4�H@�>�8|2�B�%��[�P�G������]5�q�v@P��n�W�U�Fֱ�^GS:ȴ��|��{tVnP�D�6�RǨ��<L��or>���L����]�yw�	��"$�(���Ah��MjNwj�X>�sg8Ey�Ds�x������ؑN5<�ok����tnK���A���tBH���E��������E����9�8���D<N�x1�J�D����1��I|�u��b�eٙ�ؚ��~32=��٦KrHv�l��r4϶	p�����{ٍ��ziko+_/U+��k�~7>������������g�	K4W�A��*����N��Uڬ��?g�~�;�4y���ې�;^���C!�}�q�&;���f�;�d�����/M6�d�r�߭�To�5J���v�d�'�f�.$��d���cC��"$�HZh��?x�G2�o-]'��G��#�4��ʏВ����h�"��剬fQ2q^���0���x�f�H }�LN�@' |��6�|�4ډ���@Zy������f�KV`Q�wL�\h��ĉ������iH �	���������`ra�^�Y>��ۤ�?$$ |��
�V13*�i�)�34b��$aV 9�<.�8��\���l����l�Pv	o��aZech�Hx�ڧ�ل]�@8h�
�6��l��t\�r���t�fT1������i�N����(!�s;�M�p���k
�K�$0���Q�5�AϴU�1���\6uS9P:�fkS��^a�1��{��p�����V:�!v��=�B��ii:FQ��1Rv<Ȼ�-l��P4�I 	�ģ��0��F�Gk�	t�&�_�%3�2�=���瞽��U����F��qa��/����ow�y�oZ�y����J��s���2����̰�ƐsW1�%��y�^����a�G~�9�����Ŕ�����D�.t��I����N�1�������_L9���*��me�Q̢��DvqUl�X�6�l���������1<�ov,Bs's^e��Om��:����0��}����G\«��i�ߟ>Rb���5����3��+�p������>O�s"QL���?R����1�i��f;.¶mڷ�ek��_��veCu�9��`��v�6�q=�ؙmx�@[�(:�9�QDE?�!��{>�m�]��+"�}��}L��ɢF�o"l�M�&��O�P�T�q�žܵ�lM����gW�m�Iv�#86�^�$0���"��]ē�y��؅N���\XX�D:X�n�ǅ���j����B��hM�f&}���T��?�.w�ʛ��D��zosa��h-�[�8�3���r�{�C o[YAa�.x�!:[��|��]ry��/�'�ƜTϯ�|��d0���5���;5��.l�7����������x�S'�m	��Z��/؛�$⡒X"��Ii�7S�H�mr��]<ET"����xgx�
`�A��l1suP�3�9�C�l���6�ݎ��{�]�	%v=�S��cl����7U�!��	�n�|k�0���{V��XOBGd���?S��lX��k츏d���v[�bf�䈗V��%���A`��� h6�'yQF/�{��İ�L�-������>t��fqK0�� �� ..�Y/�U���j~��ZZ�J���cLt++#��tEtw��I0���Hsz�Qz(���_�a�]a��&��D����3�4֛�oi9s��
��O�����y4� �?񄘘�Q^5�[D[�Dbۋ�їOQ���r�6EO��엒��Q�R���Z�wХ�
O�c����<y�Pý��)�K�R�q�2�(�R4MO�͙]ߴ"��)g������i�q����ҢH��<����\Dy��f�с|�/=����������8��q!�X�5��v�E�\���(� ~�I�����I��>��g�^#%B��� ���W��"��x΅�G�?@������ja�[0��l���k18u�j��=T�`��*��
a_��dY�)�K�2��|eoc�2����=.D�Kht�x���5l`G}1	!�>;���'Y���R`�Cr& 6��lhG2�\�hbb��Qk`M�ռ�T�!�c��(O�8��&��g���&�3��$��5�R�!�@�K�}]J��� ��|�t�ѡ/�������J��G�o:�:Ҩi�v���{��Sl��6����=�e�(�:T}J�T��T����&��UE�Cv�kaF*��阞�"C�"�����4j������ܡ 0��e�b�G����	lF[c�gs~m�I,"_����˜���͏�1�-�ʢ.yab	�m�yԧB?`.��T ��,�)V"���`�#�Ra���(�ςf�)_�5�G�����3"2�;#d�0�\3b��2Ħ�����m��Z�<[stւ{�#'@�Ī�\U4Kֳ�n�r��+ֹ�����t����&fq���
wR�v�&z���r�@��1mr�c��.�&fA7��&R�h��~� �6?�D�Sl�!_-i�6<hݶ�������.�`Feݣ�Q�k�S��)�?�m��V��C��}w[����=acv*�T!�eQ�O�ƈS�7J���8=�PI�Ĉ�$ ϲo��cÑY7Ӧ�&F=-#H��~�	��6,S9�Q���_�,�A͞�hdf��������_]eM����3�'�R�7��0ݕ
ȭ9L�}�a�%U�����%DN<����]����Ŧ�2~���N�G/M��oOя�&�K�P,#$�3�}K;�$Ϣ/x��gA�FX���بeP`'#��DD�����j`�1ߕ�Z���" h-lwa(`gA�s��>6���IM��ds��d5�?N�I����#��L;���Ƕ&�0,u�☱����$��O8��ʹ wU�}ـi�=k�p��!iX���='s�C��@ߧH�F0V�&�o�۬�X����D��Kd��I6@9g�$< ú�P��0�������<��	 bW��J�,=�4Lw27Қrӂ��җ\�>#�=E jS�!��͇��x�4UA�j$&��x����d�Ü�����7&3�sw�Sa �.&ȁ�y1� �BD�f�_�d�z�	�������;v�}
�S���iqj�/�����.�p����=����w����������}����x�W	1��REHd�V��P�3�T��bZ�	'R�L3O(r"��d�fz9)6��������nqH
�&�^�C\�
�Kd-�tu��ƻ<�C�΅���\��ˡ�\�D���+��x�a�]�:qB��ʕo����߅!�'���X܀�~#�� �0���1����+�0��g��M�<+�`��Og�E�G���D�����_���
���k_�~���?�ѿn��o����?��Z=�����/�������C��R�~O�ܣ+��{|�Ϩ�x��Ӌ=����D*�W��ˉ��N�����tS��J��&��dBɈI�\VQL��匨��\E�j�{��������|����\����m~����c����~̇~����{�����~��,�_������W��}�[�j���}�~�_���o�����)��Z����z��Z�K�"��ʥR����K�ۖz���.�
�������[�~/�����v/W�6r������f�V+H���r��q��na�V[+���le $	��|��QW���C���v��\�����ʶ�ꕊ����Ye�yT|X�)�s�\k��孤��V]e����V���RΙF��b��fJx���+G�X����k���C���6�����~�H��kWvr�nC�w�z�WdC+{Va�A�z���]�S���V%ڶ^�	B�]7�u�݊����r���ڣ �~Ư��ww��^sm��3n��뭵)L�+�+��[�ـ��bow}�|X:���Rm��?��R���"wP��n��|p��*m����'����S|�t{�'���!��Ni�`鎎]iu�^�A}��A����V��'�C�V�N`�#WZ�U�W l���T[��$���Z�,-�YP�|����[%H�B�7�vO�s�#�"�]�%��v��&����Sl��n�kHO�']��d�c&R���g����q��XO�|{4�"hh�(�R����1}{�����v����e=ytK����o��D�Q�����}��/�}�+�ɔ|�`kۭKkƲth5S�;{`o�,�(r�Vyy�يq�4���qs	�ɩִF�I���.U�Mc�rk��rk�f����z�Q�>W���t����r�x$ՙZ���J���wA�=�A���/m�6�Q؁6-��)�U��hW�?���Gq,=�F�Q�;;;bv5��h3)
����/VZal���`�feۘo�����:w����2׹̿���O\UP5EuWwu���:OK]����<��s��Tv����OX����q3�FN��9v0dWX���1m5f���F���n��eL5e�iʘ�_CN� k�9)3<��3�!_��N�$��+��>���r���W�����<N���,'m*����dg�jw���Z/�׭1S��ڦ��捉ե��߷�l�j�0$Uz@��P�Z��a�Mq/I}l�\Ce		J{��~�=m�Z ��Uh��WDv̲*]� 9�'*_gen����9Z���>[-g���v��F�*���B��ި��|[Ǧ�Y$`U���:ODu��x1X9f�#*��!-�eZ�IϘ[���l�!ȁA֩�LS��Eu!.mQNT��P���Z6�y���C��f�����}}a�X��e�?I)��hG1�4��aG��L��p�Ji� �����2�`����o�N���� ���}B�Tk�'�(�=O=��v|(�=�n�8����z#�Т6s�-���qX�<@5<�ev��~���ƪa��3�"L�)l���В)�ڱ�A;��Vo�b�e��}R�?�)��K���/�,C 6�tDm{�5�hJԚ6;>$�Ke*�G�*ym�i��-�4Qh#V�Cg�I3�:BR����	�$+���2�k��V�j�	�R���Π�\�-h����O|��m+�L|C/;6�l�����GK�]�E�����_|���{�Q��[���W�|��]qv��~s���*���[[���ݗ�����[�8�����7��73	��_z�?����K����E�����J��]�n���������ng�K����q#����ҿ~[��o�ϧ��Q*k�T6�oc�W�M3
�g�5�n����^�|���1�*��)����~�&�kbĄL��sAOQ��1x��z�j��\�5u��PW�g���uN�L���B�R�b����M������r\��,��al�t�Vk��)�,,[^u�C�"�m}��P�9Cd�_+�3�5�#�b����RJ�݀`��oz����R�.�J�L�y�2����������L��/��Y�m���ɦdZ�U��0=�x�v��,�X8َ/��n��c[Z�������Y�ܟ�:��@h5V�D6dÞ���z�����l�E���Ĥ�<*� !X�f�N�BG�Ns�D"]�Qx�ͽ1�ʃ��a�c��]Y��z/ӣɛ����h��S�윅��W`Y��tu�h��F3
6���"�/?x�靖|�����z`�'�,̴�)>B�^�=�qU�ﵱ�ׄ�^�.����c��X���Sw����O����c������:q��F��.�Cw-�A��a�V�o{�j�����;����\�X��Yz֡:�k7�x��g=���.��y%��x����_i�*F�p�U��Z(��B�WY6�_w�1�뉼`k�S�E��9��v�`�oʴ5ZՏ�Nu�:+��^�j��ۺ<bU{Sw{��'��R�&fg���*��r2�WU���m��a�$*RM�'|-�E����>�E��A��urQQ��I�ף}B3�@��$�����y/�7*�p�����U�8B��d�H�M �UO�q
=uF���`=u�L�[��`b��)��S9
(�]��x@1�9�w�n�_�#jj�D�E֧�Ld֢�L�"���U�ݐL<��%jOY��k0��T���΢;��顲نP�0Z��:E�
�i��^������ڎ�([���屇�\aMlB�����P8l��
��B��n��î�L��cv-v;��)Fz��(&v`�K�]��3'Q9j�d �1ݛ��k1FS�6�7u��.�ou�?�~Ԁ/��үK_ݕn狰�n|�k�[����5�_C��hѶ���j�8*�8���o�_����<�D���7�/�/�E4�S~�������/^@�����o����9�������u��s�vf��_q�Fמ���9���z�٤Gg�Ο��A���(ݲ�����Ri�P��>� ���>;�o.0���*�?��^���:�.C��4�y1R�,��~��eH��"�|*/�Ϯ���0���%�o��^���@��l����Z�{���폣�������.(��)�ch�L�
~�����p��E�;�?����O%�]Hw���Ͼo|������X�o:��������VM޷	�d��O�:��	���G!�����?�����@F�]��.��������%���	r����e�7 �����!�?
�?�����z����������`�''��]��b�?�_-��dH�Ȋ��P�%(����� �m�����.iy���B�?���Y W���� �
�����+��� 㿙� ��<����z��8� � �Yg���sF!��^��,�����X�/������O��������W�*��Q�������������m=��V�=�à���ܐ���ӣ���	�����+������`@>(���������0��|Q���@��\����G�b�������������A�ߌP�w)E=ĩ�C�v����3�G��=��
�yt�C]�r}�a��3$�!̑3(�"�}��"�?N]�������V[�m��u���R�D�M�s���؀�u�y�A��ٛ|ZW5�&��:F3���\}��-�T�Q�M��Mu�75�+�N+s�N%���khwi�7TdSm[�)騖�
�bL�sN���|�Z�A���r�i2DX*�߻���?����������x
&}�"����C��������+�:���?�g�"�?���C�?�TL�T�-̂{%t��0���-��&Oo��x�����Is�5���q׋6���fhϜ�(����u�S�Rݮ6�V�]xU�;C���xK��j�Xs{�M�u 7��>��<�o�B�� �9!���گ������|P��_ �+7��/���@���/����C!�I]�?�/<Z��J�5o�_S�uu�헻�$r|r��������-
\�H�ҙp�t 7�?��mc���E��I!�� �oF5ca�Nw�t�2]ᰝU���U^���Cy�d��l!�f�:b���:��K���P��u��cG�V*K\�����iSV���������)Xs�X�tW�JSH��wji��4����(����Ū�l���+��;�O>j�*�,�Z�Z�QT�ܪ���&��z��f3��&�7��+��Cr��/GQ�f��E롡V:�����QT�t%�n�v6��>y�wE�(�����2�G��`��B#��l�yh��d�B�?� ���/� �E^������y`�W�Ȕ�A���!+���_��o6 ����_���`��\�?uQ����2�`����������zQ����Y�?��X(��`�?����������������?��Ka����E����C���y)
����� �?��_��/`���"�?���兏�oN ο�Ȣ����qP�7������P��?d��7������; ��ϛ�1��_
�ȗ�Aq��������rC��2C������?q��/X����� -$d���Z��?eP�� �@��|���������(@nHn ��y�B�?	���B����3�0�GF!�����1<��!����������(f�p.U���j��I��j����H��<��ug��;��Oi*o��n~9�T�Ѫ�l�k�5��ب^�ۅ)z�(���i���װ�ءqË`H���
*�~��xwcnuWé���w��H�K�>J�@�'J�@ޔ�Nؤ}t�V}Z1��Q��
�x8�$j�@�ݍ��1۹�EG�e����&�{hH�[[n�]x�D��PT��{��%�h�l��;��}`����	���8d� ��y�B�?y��/��!#��Aq��Q��@�G��L �?�����#���?���?P2O ����_!����P(��!3G!�?�����#���?>_B���9!�7��Q�X{��������+���e�G� ��
��CЮ�ӾOٮ�Tlo�#擈CJb>�!�#Q�Gl�}����
�)������(��ԥ�������o����}_�'�/��@dUN���J2T�9�.����D�q���؀�&=����W�F��PWB&����6�ޠ�T�I���Ly�f��js_�/z\�ew���uh������&����n��v;T�C%���C����NC�����k�Z(ʾ����w��.n*��`(B��?�C��?��I�|Q���_~(����!��~�WG��g�Q��/?|H���6Sk4�:-I��!	����1���W5L��K.	c}u�����U�\a��R �͜��|�6�	-�!v��wi����p����^*^ܔ���hnM�r?K�����	���E1��E��&A�����~�?ŏ�g�B���_����/��������� ����H�/'<���T����k��%eͷ-���؊;+d~���g��nj ~H�����)�n@yD{*R�ʶ�2�˲�'�f��q'���e4�(�h��xP��=E��9��M��t�i7��2R�Z��U���ynr��̃R���lR�otwu�r=�s����έ9Qt����F·�]�AE厳gTT�_�5vzz�t��|0��L�T�!IG�_ֻ�u���,TqඥҔ_��5$�L^����56<���n��]�'���Ծ�,�Z^b��'ے|�S�s�K��ǝe4c�HOt����Ƌ؋�I�PY���k�F27R/��z�vHW</3�l�N��z�;v�-3��("aߝ�G�;*ƈ�LCC�A�Nh��&��?]������_g��u��	�A������?���/������X��������/���_ ����?�%,�8��$y;���.I�0d"��~$�1O0d@���(h��<�����A���_Y�����F%��ک�`'A�$K�q��b���^���+G��[���[nQ�Ѱ���J�����?�q��G�����Lwh�+(�����$�A�I�U�/�S��(@��\x��APAȥ<A���R\_��HHq��I6M#���4�����OB�<"b���D��Q��	�����,5���p��ǻ�(�o��!�B���iLN})���^�+�X��}�\�V����������U����٫��z�������������/�����_�T�7�K��=ޟ���GC����绌�K���?E������+����@���Pܾj�?(�����00�	u�0�	��#���w���J���^����$T���0U�_������UF�?
�뿫~/�"������?�*����:�����P&�ɠ�����H����0$���g�_��,����k�ꄽ)ϻ���#h	S��Rj��̙KsP��|/�R��3r/�c^�ѭ�I�Lc@����ъ�L�3���V�dZ.�>��&3��<�(�)E�O������!�*2����ʹPa�/|{fj��a0��~s�[���[�I�������fEb�驖��/�E>��-$�N��X�bt��*�n��n�P|f_:�ɦ0��ޚ�nk�,��^l�:����^�m�8$��1Qm��^�L+5�x�ʞj����.I�Ue�+S�J�:���'*&�o��Ŝ��n)�D^�ͽ��V�l���~��
%�Ƚrp�m�]a~�)�9��8?w'�E:�l�U�-��%mQ���n�\��4	���c'�_2�Ƭ벻F���"�Z���=d�����˰���{[T׼x܄��;�;C�$��R����VV�����o��CB�b��!P���v�W�g������P/�|$>�:��d_�?��D����z�����Co=��)��|��re�����.���Ku��s���
g���A�!����ܯ1���Xw���R�F��D�5�I��񞣓�����k��k�7��[.㣩�9��C*#5%���(K�j���ǈ�3���]���뢤x�$uq:�(�9k<�ޜٳ�)��NG��݅7▶�NC4�A<����9S�xk���m֧������q��)�*�Ԯu��p��Z��g��sQ4o�����`aʆ�K��8I�lgw���nV�$҃^o��m֜�F���`���멩�DSqe} Ӆ1`1Yɶ�3Ih>��'4�k���t&�=�	G9nfz6d6_Y�s��se(zi
�a��G����Y��[�-���]o���/ ���C��4  � ��k����A��"�f��	 d���3���������a�v���~���a��B����K[^�_�������i�O�w��݊ �I �4F�|� {���5 ���E�>���i��: �`<M/}���m����Dv>aQ��{����c[�O#q�i�;�l��3Og�о].c�?�d�)� e��� ��B���p~.�Yh<�W���q�,������$".�ْ����}��ڑzvP��+�ɘ�WHn�l�'^&�������uq���ckii2QԞ1�����vQ����4�WG�])�K����ʨC��>����������2j��P ��:�8��8���8��W[�D-�?�A�'	�
��-�s��w	������_��"����Z�?A\��O86L��)�Oy!I#:�#�&��"��<�h<
�����@h��`Kܻ���?����r���e�+��)�!��=q��qb��ry\�[It����<|��f�r1p-{c��K;���eD��e���G�<��3�^&�;�Hu��So�����	Db���ݖ���*��inʰ�������?�����~	��UR��?��ꨅ����ʨ��߿�WX�����������_���e2�ƾ�����`�F7Mdmޏ/�z��6�?���FY����,���pi]�t�ᐻ�T�g�Ck���8f6��%'��ַMwr��^���I������(r�LJ�2�Ck����
c��{+�x�S����:<����h�;����P��_��_���_�����*��@X���p�a����g�_�i���=��:���=yǮ��A1?�R6����_�����=���v-ɗ|�؄��q ���Ԧ��'j6Zǅ�e�6ل�4�­7ӵ"��q$�n汸]Оٙ1g����)UX�y���}��X���%�:��o��m��ӭ�o���-��t����2�-]�t�\4��6��@ԚY�O,�8�Z!O\��N"]V���5�Q�^aѮQ�n�DSȺƝBw+���$��8�f|���q��Nݓ���v�!�$����A�q�X�� �y���L#9l�E3]on;����+P���� ��_E x�Ê�������P�AC�j���+���?D ���ZS@�A�����A�+���pך�J�߻�����H����������j����O8�G��V����_;�����$	��^�a�K����P�OC�?����������C�����x�)���v�W��_��V�ԉ:��G�_h������_`�˿���#���������( �_[P�����kH�u�0���G�����J��[�O��$@�?��C�?��W�1��`�+"����,�a��<��AL�	���B��<�'TƷq�E�1/$4�$��ﳨ�������O$���~/<,.��e&���3��H�O-����vD_Xˤ��|��0�[�x�)��px��f��U?l5��(ml����f�*w�N*�Ao�G,.��R򕔵�麤��v�@�mg�éU�?��:<��G���(@��OpPOP�����i��(����ă��p��d�m����{���A��A���A�_����*Y���Bp��i��x��1q���0��(��H�x"JX�S*��
9�OB<N�"8������!�C�����ic<[�g�|�6�k��t��LO�Y�У��"�FG�y�����fs˦�+.U�ɑY�TBv�K��s��xw6'&i`{*�LN�B6v��d��F�n�����q���t�\� ��V�����u ���%��_SP����)�����O���4�?
��������?<*���z�����/H�Z�a9d�����W����������:@�A�+��U��u��E*���G����� �`�����?����P����e��"������ϰ���?"�^���"H|u����?00�	?���\��g��s"�c9ً)K�`9�n�����]�j������Y���l����c?�����n��2	ɓ./�奙m��`k��!FL�w�.�au#�+�h�tW���$����[�cS�7�v�����f-�T�'{����'�)�O�^�MQ,����K��s�/6{��o������T4��]H̠�9�;�\'�<YO�s��$������*>gb�9Qly8MZ�F���ɾ0j�%�*b]��>#�#s��&��������^x����:�?,����r�����_-��y�����H���Ô(����?��D���Q �`����O��!��*��a9x�oǗ��׎�j����+�f�/�~�_��Ȩ������������?����-Z��zd5�qSR������b9x����t1S\�=�ԔG#�\D�n�3G^X�P]����xʩ=���"�5�~l&�X�j_���2!���������ٿ(<��c����<$����5�����^Xj��2����:i::�stһ�6z~��Rx�e|4��=�2~He���(Ko����c��Y
���n���뢤x�$uq:�(�9k<�ޜٳ�)��NG��݅7▶�NC4�A<����9S�xk���m֧������q��)�*v���Y���jYK4���mJb�+�\M�x��z9X��!��j�N�%���Ei����0������r�5gd��� 8�b��Ǻ�:Y�3�T\Y�taXLV�m�L�.�	���op-�I�k�-G�Q������WV���\��^�wb㑩�|v�i�;Ɩk�p������?"���"9�|���G�����A�)���G��H����iHpQ�q��D��LH��B��	�!E|Q,�\DRa�S1�@�x�Î�wS�8��?~��������i&��f�i�X��qwN��(4�c����x���c�Y��ȑ�<�
-�ě�~�L<wy�&���3s��[@�M7�1�z�VI�c���]�s�J�RU�T*{���xkK�����W�s�۵��ie�*�ȗ��u���u|��pdd*=�*T���U�'��dk�L�7Nr�=�5�Wu�����Z^������|��G_�>gy	��z��|�E��u��g+/A����|nj����������+��sǵ�{P{{i|��{���K����šUS����s%�a��z���a&߬}�Z	�@S;�a{���G3��H�єJ��4��$�;Ӹ4�';o�����w�v;�F���VZ��k��A6������U��X�3k��3����+4�X������������+��_��_��_��_k����{f���|��"�?��������S�e���7���Y�k�u�*%������U5U�jW_n���������z���Fێ��5��; ��'� D����; `�*{u弴�R��%��w JǗ}3�>9(%�:f���i�/��V?�z��(|��w��N��ޫ|S�o�������RM}[�5>�^ժ\M�O�z;�η�1:�*����x�}�i ��y��x+x��d�<9*�~�*j�e0>#��.4Ӵ��Z��w��\�m��9�V�6��[[���L�i7�'�Qe 2��o+�FY?�\�,��t%R�,*ܼi���jǕz��A��rǻ�-���M)����`��i_����1���_?f��y󰤕��v�u�fwZ��K�32������G��&��r#��4��~8��/��D�?���S:җ��D���tX��s��z��$���㩥������5�����6>�I�q�P�W�W�Ӫ~�j
3l���p��Ƭ")��2d�t<	��b��
@�6-�Y�Ұ�$F������3h�5�@3�!��2��Q
�S������`�H��X1�!UsD5�Hf��}#�hg�>��HK؏6�1ݜ��i�4:s�i�:������G$̾i;'�䝇gdo�+s1؏��&�ſ�ԣ2/?���]�c���?1 �(V�5��L�☄��3x�@NǺ�h�H�����6�25]K��kq��ru�:�&���bW&>"]�{'�Q@�p��	`DB-�N�C|x9��l�]�5`�l�}��U��I`��U)o��$��7m���,�n��K?~��*�MA0p�*��x Nhf�7�4�ʠ�&�(�̑�f�Q����T���.ضҀ�Hp���;1;Zp1D�;K����7���8|�|}��d��͞u���%�]`�2G�fK�������=FF�d�4�h�ж��7Mx��Ĥ�S�'7�E��P�3u���ֆ����~W����v���-���Y�R�Z�<��x�œ���/`ڙ�/�\�B
$��12-&U�3�@"��X�R�d_]4���O%@�xԗ��M)�M��j�Dq9�5*Z%Q�TL�pb)����.,~ә\"��;��2򕐼�6��h�;�Tj�ʮț~ߔ��0}�wq��WTM��*�����ƛ��xH&H��Q��2D��CF��"A@�(�k������	�H�t��T�6���S�+����z�7#:�ht ڥ@C��h><��b�f#�G�nH�1mE��_A���E���D�[�:\]_��:N��5Ԑl�x�t����ɒ�A7ġ���(��&g�SU�v���3�<F|�s�d}���j*̊���2>���d��˦��?�Lg���'��tz���ORpƁ5��u�u$�, �{�C�0��Ft B=����3u <!YF�ōR���<O���Ԙ0#�q�Y����l��[*�땳J�l�yT�I0GI,+ysA�N�����O��X�t������E�vE�#��ܠ�����B^��,X�Ub����_��wHrWJk�M�2�M{���z��V��R5�fY%I�)��|v��[�-��=Xi&�V��Y��R4Oٙ}Ab=�So�����ל���X�\����(4Q\u4r
4j�u&�[�R��o��|����lq?n���6p�^�Qk���{������������n�Q�V۵Ng'��n���wꝣZw�Y�ANYVu�~�@���+_��̀}�����T�tx�iի;�m_�֮��7Q�ߒ������pg�fI�;��9��0a[Jb ����<us���k\Zs��DyO.bp��7��#W�ZXL����
vb?"n�:O!�}���b�_\w	�c���}�ٮ!���{g�8�W���J�:_�Z+�셫~<:�5��f���q���H$p���V�rix�� ��0��#�������n�VmV��~�ӭ4����F����>8���x�t4iÝ�dh�

Ь<�[���M�A�}���B��m;�R�&�VK�R�ԩ����;�W�'��jY�I~��`s�W�moeTR}����ⓘ2NV�1X�;�=c��r*<G�%�O��'|��M�}�*����5�dĸ�����`����X��W����P�30
}r޶��;�#��<vY���zw+"�m�h��1gܹ@QU�g'�C��q��	X娎�%Fwmg����>K���ohN��j�w�V��Z��KfSٹ��l!�>�}�"tX�-A�P1�Qv���#�
E�߁���j����#��5���"G�{��$1�uƮSF�u�b��N��!5�{�*�]&v��@��x��U⽖O�+5�����~�,��d
)���K�D�G.����(k���������?k���������?������n��>���@kw��ݳv�ܻ���s�Tsb��q{�z������W*"����&����4���=�H��=İ���D��Y�C�e��;2�4�!T�=�m�#;cФ��`��2��k�
��?]���Y�ǃ�ײ0�V�mZ�x��������7�et�;�a�g��I�R�#��u�lFɯ���D�O�3t�%�]��L��jsk�AO�ѻ\�;WG$�����R "��]#��"V��\�ye����'�^����i��I�I��߭�F6ބ^�Կ���M��tak:��Gj6,����k����v���>�e���g�N�����Z���<��?�"��#~ͩ�#�O	���G�(?/��X��˽�xi�G0V�XU,��\F����g2�$��d2���IJP���/�'6�?o6���/L�$�>�7E�CY�#�ؐǓ�����7ڋ�v�{��ӁF�Cn������up���J�"Rkm~�c��_��1Cޝ��Fs��0��2��T�x�� b�8�🩸9���'�N�P�q*r���e���5pqc�N����l�"��C��� ��/�(4�F
��/� ]�>�ď���[��nSDL���~�u�6�"�ᦿ��=���h��tA奢^�`���!:l4�G�f�;�!���I�@B�����������?"�������"�(��S�LsN����W�_Gp� �2dʅX2+�U�[�L!ގ��D���/��T�2Y��I�� �0\]��y �E���v���w��f#�>��$�]��c�j�����T�2|?�,��B�������>���+��w3�%��������S��s�����x�bv��kH��77�%8��"�l0qcH/Y�f�J�ux ��y��,K�A↌�@���I��K~'	g4FS����m��My Z$Q��E߉��t|�糅x��N���G	�Xc��H �k_s�r�\�I
���	B�@�l���G�k	�;�����!�Zx%�vNڇх�y�����W�D��sC������G��=�W��o�4�F�tx�I&A%�\���Y�j_�[?�����?2�Je)�%Y!��'��V&����f}%��R���ˤr�-�&0F��*��^�@�6�fs�3�"�y�k[����\��.V:()P��_������.��۪����ٚ˜���u �����J�]m�t['�.�s����L1j/���=��XmIl�X�I̝�纀3N���/&�gV��Ed(����3$�A�0�r=�o%Y��t�D��3��o�ly�!�e�;a2�:_ZN*\��������v�T������VF'_zSk��K�G�=�޴��I��p��'����I���?OR~��#$��&����3`��6e<�܃\�[ˊ��S�ѴL�����N������<EYu��1����a�����,���.���OS~��� ?��_�	�̏/��~�;&1:�@BL�4���p7%
T��ЃU�S�&�,x�3-��&��l��i���n��=�֏j��y�S{�~���Eu�#����ַ�����%���1$�b�-1f"�G���f�Mt���lΕ��^!jqϏ�~0awqJ@�� �Q�#x��+?j��zt%#�����e������D7��#K�����>%)��ɭ��<I�y�O:�5��}�\@��ϡt�^�r1ߓ��������&��e��V��0��>���W�c.���=��ʿ��� ��j���?U��/k���˽��[�W��+����`����O��T6�����Lv����<N�_LH����y��b�����/-�L�ޡ�͓���vy�*�U�|W3Em2��@�2�(���c�:v���#��������`v��:�{��H�.�TE��:�
�%��^k�迭@]�ph�h��ׯp��^e"׹K��H��W+�1w$�mio�<��c1uGd�x�<�f�	e"T���ك�N4.�f>C1� �|o1�Hi��Y�L U�c���9�A������F�1��(��W���	�;�������̞H�(�i\�UWЫ�:���A�g�*�F݄�@&L�1���xE$��E� i��{���! O�1I_��'��d�9�I�w�6��݈\ Z���wj*R1��θ�^�A�U� ���Y^n[��D�1^��C�����I�w|`T���Μ���!����Q\Ks�~�R�7�+ܚ�`��hc�I��G��r��M� �"���O��P���+D$�Lz��:�y%C���i�W�W�Y��1/7-���DP�g�xy˴m�A2�ژo[]C�P��U��ٓqjMCf����L9��,�~�a`a�54
�rB�D�;og�J��5��[qj�n�٘��ҵF�����I������f�Ł�	�5��I��<����z��FXJ�"��~�P�Ǥ;i���C3Q3�R�e_~[ɮ��'���D�Q���(wJD/h����	م����K�j1�_R��O�[��~WDS	|���r��O�~�em�%����p8H�C�h��Y�c��=�|y(�K(������ZQ�9m�9sG�J��E �1�F߆��ʍ^Ih^�d��R���ڎݖ�Y��{~���B�9���*u=�4�ð��3��3'���e��[�Įŭ/Ll?�����������SN�ƽ^��#�D�
B�B[4���� �T�H���=�-��?�][��XZ����=3=Ӹ��4��Mf&��K<h��-��؉�J���8�ǹ�IF�����]Ђ��ސX	^ay�}`B�����`�V����8;������������?���=��^�b��{�:j��|aF[�u�h�u )���{����&vw��6Y��M#(�ƀ�O�z���9V�h}�]/��<&X�f}�P�L�&z+�7YL��}�8_i[y�W�x�Q�����زc�1��܍9��|�<��Y5���^��w5�s��3sp����o8��� �!H$�}���8����o�o�_?�}x��~�����S�o�Gj��a(mh��`�ڨ50-JQD�F�J�:���Q5*�i*F����(�֢8��m�����!�
xi�B : /z�����8�ހ^��џÿ�}�֣yx����q�����w2�ނ^9���soy��[�K%׹q_~�M�[�˛��:9]�?RgU������ծ��_������A���,���	��N �D�?�3�~�_���_��͟�A�ߟ��?>���>�W�{��A�����{�\��т+^�f]�����?ĈH4R�UX�"u� u�#Y�GJ'p��܁c��:�#(�7�(��#�/.U@��[���?�|��şD?��?�ө�������A��o��o��?�^�������o�����z���+"�����>����B�~��>�����V�&���Y�и ��bYZ����\��iF����JR	�
��)�0��v+��e�n1s/m,�N�����`+olUd���MQ>/_lM�5��s�*���+�ź�ҜF�Ve*�d\lUU�l�,�7e@L�SvN'��u+
m1':�����q�ҴW�P�Z�j�������(�-`F�N6k����D̵�����⧌{��4�)b����q�Fb�q�Ƣ��Ԫ���+���T��,-o�s��q�A�-�Qa�h�=	�Tr�t��~3��*>r�~�7L!��
\�Z���e�r)��k�9�ŤI�;=�+nE��J1��7���:=� ҕ8`b���9��ʲr���	���"E���!qud��!o$�?V���jw�]���B�;KW�v���c��/s9��9Z0�٠�
�SQyC�)��y�L�A��a찮q�y*=6X!^��N��R�0��q;JOz5B�LG�AJ��
�-��R�����)��&�=I*-�3vQ
��a&>�I�˷-�LRim�KRi�V�I�yTj��$����MJ{� .L(�8%���%�>��3UpiB��8��22oO�X�'�T6+�R\�rJ�I��v�HZ�B����TL��M�*Y�9\Tʓ�P�gsD�gq�I��I�4^��ߑ��M�rD3�AU���P`�K��T����uMP3����D�xS���T�-�V�Yl��	��F��Tt,��)�D��v5Dr���R�)R�6#���nGJ���X�塚��9΃rQLdU؜�EN�R!G_��y��O�(t��'��xiG�s��	m�?)+H�bZs���*l�X{v�젾��GR����9�l�ML�
�D�ڦx��z�'�$� ����*\K\�����)7�,1��\�L�#SM����d����̚Ą.UJ��z��Q����>�͒@`���Us�U����v{NWm�2q��k��$懬v�F��)VU�ɼ�A��Ȩtk� Y'Ҕ��c�O�NL0*��1��`��;�!S���])�9�#�d�۬@��$=�,)�Fu>�IM�P-dZ���6ڍۙD�A/�8l�����]��M� ����}���K���R����{��ƫ���?��:,VZ�~k��z�3藡�]��`}�o�W�«����H��p������Z^�n����Kv���M�jE�wބ��5�����k����?�}�>�{�7۽�?����s�����F�IF�L�)�$�̕�zC;c�U�i��G��6�EO�{͉-��������Q͢k<�������,�KvxcE]��4�E��f��G��
x���
ch+c!0'�CdGbiZ���|Bf�H,A�	�H��^V��d@Y�4Iթ"e:�P�$Bf�V�TS#h�Sӵa/U�F�y�K��K�H�e��,Y&�����V֌d���0F��~�9:�����4�ŻP��dXF�����aä�x�-�Hr�ƻ}���3��w�%Z���t
<b()AsO��Y�g�l9^C�f��)"���I�]θ
�ZXv�G�1�Z���C�k �&c�M��CՉ�.	�$��ʇ3�l�/�G�yi�a=�\�e��B�#��t���3Cc�������S�����?}Z ��tq-����\�G��UV�>"r����gמIV�-�eܦ�)���������uw�ߢ+��s�_�]+Yc9~5�]�y22o�GC�ˎ&�je�Y�*c�X�d���R:j�L���K�X�� �K룪��T)�u�������ɶ��D�J_�D~x�	�i�v�B�_
eV�i'��,-���K��TĻ���#��N�1��f?��t�f �)��Ɠ�S�w���&-��V�f�x��'��R���d��$iNG�WE>1������E�x��&L�'�fϜ���H;	#0��2ލ&��O�����>!)�!��Q�t�]6ɱ�PL��T#�U�Ը����W�d[�G\wF�;c�;�6&�D_hLT�[��'��l����|Ҏȅ��b{�!a�<��)�����=�ҍ�T�`��<��բ�|E
��(�H�U(t��xĚG�D�́gQ�kP�ڢ�cP�B���#!F��sGՑ��vd#9	'd<��ѩ�@[�Ąr�y7�A�i3eK�rm:F�z�DW�\��Yz����:�͇\�1a�q��
<V;5Gd��H��U>�a�L�V���pV���3mti�D��
�5Wn��W�����f't���O�D2_y���Ep�Es�p40�Y���u��_w��\�����t��-��T9_�,9�^�^: �>|�����M�����׼@�@/���������E��j����Mf��8�t���9}�K�æi�et�5;��+�����+���ԑ��!�Hq>,����xuS] �V��Y���!x�qː���T��n�'�����}v�����#��3���������t�s\��]��#�p���N��*�ѦE�����u�l��hе����^̸w��Fô̅�t+�[u��ny�e��~�N���ё�εH�o�F3��M�07G��ȋ�g6�U ��\�E�7��r�pC?�ؾ�,Ա}�i�c���P��M'��'yÙ(�.n8ul�t.�ؾ�dԱ}�٨c���c���±}����~/�a�kiӾx�����[�'���#Z F�_x�~F����?�v/Lf{���Q\��ߔ���k~�z�v�����E	�Q�q	 	��.����&-�R|eQx\eY�J:>�T%��%c"z���N�.�fb՘��um�����X�jv�t��CR�t{>�G��:Hzh:S�J�lCT�6>����Hי+���}~pS�o���s\���NO���q���� X�,���~���~��#�o������=�~����� ��N���-��l;�B<�J�"	��aG�ġ,0,8�4��a�l׈�����p)�R�dY+���<��mt�t�$Kӹ���)��yLe�м�uX����]�ۅ���gx���B1��M�m��B�;V2����
�Y�K(������m��̍����������t����"(���z��1����� 7l�sCy�>��&#h�����h��xb�9���'�?�x�_�����#��?����2e��w�q�E�?9�c�	���'���������)sN�� �#�������`��/���^:5��=@������(|����~�z���!?���������`�_S�c������$@���������ǂ��;A�/���{��}~�ا����9�?������� ������[���c���w����3ۃA�a/�9��A��� �@D �#���}�^�?>��p��.��Y�`	�����[���c�Y�	���_���=���'ϙ���� ȶd[
�-]'ے�=��`/�_���?���������[�����o�� �����������������0�?���k��;���?�������#ș��8���	���5E�E�:�z�CH�^kP��i�ވDq]'�:�a��h�(�݂c:L�d��	�[�g��~��!���������_�8�A�;:1�#0W�)lb��^
%)�CM&�+�	��U�E�	Eg�J!���~!:Wu���bH�^Ob�$L��$���X��F���īv�l��=ڈ�����(T�zI��_�w�4����?��_�d����}������������O�_��=���)<����?��4�?F5D4>��h)\f`����Ci���H�aU2,9�Zc��_�)���ԥ���ԴA7�c�RV:8�8�ŉ��&�1)%"Z��j�I����(ޮ�[ɒ���v|`���P��rl��]�a�#���O���k�{����P��뿂�|C��W��W��W��W0��?���#�B���Y�	��.pi����˜迌d����誹F�h�y&O�;��<u�wr�c�q�Wk3�t S==��G�hX���g�J�U���+�ܵ�����DTPT�&o؋����O���U�ݪ�[DU�=�4�F0w���9ζ;��ڽI~>����i;،*����ae��N��xJ]*�T�J��9Zw�4�;g��)�<t0�y�w��m���:{���ne����I��|��6%{-1k�Oe
�X�<�~������Evq}{����a���5�[�G��|�U��Թ�2����w��xVXs���"���g�i�6�j�:i��X�M��k�e�^��.ɛ����X��(�ТQ�~Bj���5�[|4��r~�?��$8���?#<��@�,���M��?�����w�I�����.���GN����G���a�c��_����0��s���ϭ�H������_L���0�0����W��_,��/�!��_����>j��9�����$�?����a�a ������?�,��0��?|^�������^�_� ΟP�����<}�����A�K��@�����o��aM(����e�?K?����q�T��m�}>9����K�8�+��?T��
���������	�?L ���,�������i�b������?�������Ä��_6O�6�<����������,���� "��]�Ǖ�y��8�=�o���7�?��Y��j���A�M������-����(��=�{��U��_�T���z��K�|�v5�x��M���l(��Ҷјt�vϱ��e׋@�zQV������������*�NuN,�;�.�n��^B݊@�Mu+���n�ݫC6W��b��������Yd��5�I����j�rܸGZ	<�քLY�V�o���ٝEX��X	��E0�|;�n������J���T����������������?����3��� �?B�G�������+E�As�R��s�?"��i ���9$~�����4@�G���?/���KB��o��|��������[������#����?��R�8)�E"EFє�6�@�F`c��e%�0��DǱF�$F�,�SQ���޿2H�N���P��o��k��������[u51UGs,���z�\?�t���¬k]��ހ�%}i"���FZ�I*]��E_����Š��F�n�/k�8W*��z;��+�툭6�I%L�����^��C�\�(k)��,M8���q�/�,.~���O�y���I12�x���F�ܡ^>���ݽ��/8a a�������?_��o� a��W����QJ��������})>%H����W��txXg�ZбZuJSFuɣ�Bs7=���\�WS��������=�,����M�����Æ_U��i5����9F47��:ۯN���r�Z���m+���t���6K��b�ţӆg���(�X�����?�����p�'^��D俠��4@��A�����2�@��� p��J�������o�ך��8�;q��Ћa����]����/= ������k!��:��2�he��!��ϥ�҈���W��Y-(.s�O
��r�b"K�Y{�}��ڍ�����a�5�:#O*����|-��ӐZԽ��=�V�Y�5���jq��,��kZ�����D��^��j�7SY�6�4d�փ�n�[.�F�(XC�����]M��[�}�,'��*�_�]����z��fp��2��K��6ꑛZ�.��f�Y��Wϫdrv�~�-�}l�(^��2��5���h6lc4�ě�c��pc����G�������_N`$8���?#���4��b����E0p���������DQ��0����/���_@�}��/ 1��H�e��b�eo'��x�H��(1HF2}�Jx�S�X�2��FV8(��@���������#�?����Z]\�95�O�>uR�q�jVN|7��F�M�;�zX������l���ge��~$��̣�꿰�����;y������U��?����pW�+�,�?��)�u�`8H�|�'GJ̅�>̋��<K�b��)1�@����A2S����Q���X�+��!&�Z���3VM���~<:;�8D�S v;����������۴2�3q�[Z�ߏ����f���$�Y�a����������a������/�����_�����[��;޿��4��0�����>a�*����ϱ7����A��c�;�����������C�~����q���ot��$�?K�����p���l��P*���������/0�J�����/���?�����J�����e_�O	�����_�������?D}�u��}4p��?�d���x��_8�����u5Z��<��g��W�UC�GB����&���.������̢1�/f߹��[�Iל���24�õ�����Ѽ���q}�v��ə����bN-|���\c��oCT��m_CT�[��z��ρQN����gr`��f0�9�eQ+^r`'�����]�7�")���e{��o�E>�I-=�ǚ!/�Yž4gm=m�f�V53'B^�w�4k2�ܝپ���U���v�v�e@�.��{�1��Y]_�>Q�!7vjta$Oٯ�-ڥ��T��vT�)�ո^G[�V�}�����O��� �ϡ2޴/�P��I�����<��ڭ�IC(f[^<z�h{n�7�x���oS�F��#����������6Ff���I�W¥2o�⾒���MCc|i��n[�U�":{~�U����@�O�rߴӨoR^�ȃ�W��aD�G����<��@I ������������������ ������_��_X�=�o���f��{hon�<�j�y;��[s�����˯�������˴����u�Ԁ�OuCE��q�&�Ψ�����,t�~X��u�6���������1��1j�Ђ�^��neP�{o�2bG���)�bx5�9
��
mB�S��J۪f��I�ky�����u���|�.�\4f԰�oh�Mk9H���QSm�д7��4�&ia�nO�3g���<[I�\��Z�Qy�z*�z��p����P��=^Յ�:����م�t��jk��$��j�m-��z��{Qh�v{O�5љ���#tp�헗�TTF'�c����|��DJ7�]�G��.�0T��ͤ"��6C�(G}ZM�'4���m�����L�i�"z�h��;���u^��S��~m׏���<���_, @�=5��r ��s�?"�_x������,�� �@����������{��������<��LW�Ft�	������?[�������oMT�[��d ��f0��Og �o��x@~�H=������yw�z�f�#6tג�ʄq�|.M�}?\�Wǚ�U�uv9�l�:��:�Q�|h�|�G��[��Jg�g�mZlQ,x��s �k�=9 i�U㊮*<�(�7��e�f�_o#uq)�P��b�ͼ�]��/9��Z?�J��fM#f��P�3�7��f<L��Y���K�VG-I=+��d#�j7sџ��}ء�tl�x���(�k�O�< B���/�?t���r ��s�?"��i ��! �$�8�/p���p��[[�"�� �ɀ����2:g�v��/��?��#���o�O����cI��0W1Б$1J2G˱�Dq�r��,q� �SD�O���%�����x^�`J��A�?���~��7���VKkn�Ue�Dj�Vt�E�5\������n�۰���o��Q�<������Ԑ.U.~���� J(~���^W8�U$��:k�}6������f#�j���Q���:Ҝ���a�ۏ���������|�������_y ����Gi ����_WX���� ������_��:!��J���ʦ�Ry�Gz}љ^���;kL生��ܠ�׏�y��[��*߮���~fO竃�ţM���ItbN5{W��-�w��l��,u��9F�ͱi5*h�i��fљ����GA�����oI `��_��O���H�A�Wy��/����/���������,D��?��������S���������鍼lq��Ļ������j����n���&��b�`�XR?��K[�~���j�8.������4H�:�SS#��v=���^��X�d(�݌6�n�\��rɕ]�e�{��1�/|��Gn�Xۂ��v���J�z�?�:������V8�������]�:u�:�w��,R��$�D�uhF 3�|߈��:�e�rGm���\�of���ꘞnץS��Ù�Y&�n.O�U�j}j�&q�pP*Vk9i�s��QZhk3�d��+SEe�IZ	����x�
����?�V��������3|��#^I�����?�A����������,����ߕT �����,�A��$��h�Jp��{�r0�`�+����0��T�/��?����?�B*��n�G��,������a�Q ��?��s�����C�����������x!��?��#�������#^�	������`���/0�巶��
$�?�P�σ�Á�_�C��\��?������ �������_,���p�O,p��{��������C�����/U�	w�?0���?FA�(� h^��)�2lć4RB��+�Dˢq(��,#!�e���R� E0���@��4����	����W������b��0^�&}��;���p~���Et~�	����^��{W�ݦ����S�8�NҎ%@h�{Z�}��g���@Hd!�M�O [���ɋ%u���sDQ�*���ս����&����=3�[f�4&��rny�ws��}��7M�&��|�dH���XP3�\���|mh�yf\��M25/��x+���O���x�?�?�>�)��C���������S������x�� t(�����&
����I���x�_��/��w��?�������С�?��E���̑j6�P;�T$5���"��l��a&G�Ԕ�JgSR��A�T 2
D9�x:�_�?��q���_=��MW7-����w�����%���KU���L�Fl�Ka���,&�ɻ��$g�U��h�6�)H�\cL4:�Vu���Sj���M����<�v�z4��AǞe~�"�py#�&?Y$�B�+������G��8K���T���3�������S����O��:����<,�b�������,���@td��?yd��?����?�g�'���N ��/C�b�������~����@tB��=
���:���������������9�1���A��?G��oC�b�����N�C������ǃ�I���Lq����}�@I�� z��=��K��?{+���G.�f�j�m�L�����E�W����h[�?�u�e��xͿo���E�\I��"p�vx���In��3�t	ZLs=����TƋ�?�V�}�V�*�O���Bμ+3*�q�� �n��d����=���C����/�߄��,�WC�~��m�b�;n<������w�N�2a��N��i����z���,C��`As4��GY�k��F�T!Kd���fo����:�d8n�C=Ə��O������t���ƨ}��I�T�����=�����q�c���G���{�'���=������������C�)��������?��?��?��?��?��l�����8��[��������������?������������x��x���?^�/����6��9h���$WZ[7Y�fF�����B����Ч��������N�Dk=~֘H%c��sO
�����^a���\���E���#:�*�؛0��J���^��7��t�9�nz*��\`�0O�'Ѝ	Q����'r�ޓ�ƴB�{�٫�C�6��M1�r�e�l(���2�B�a
���W���Q
nL|��E���\��UW\�*�V�^}`Ֆ�ƍ>��i7S��N�+���p�5:}u$V�jQT����g����/��lũ+�Nf���W��W��L��>|!���}[�
l=p�;u�Us;e�:��~�o��|��ps{,zY���	�S�����bޅrEl6m�/f�:}�.3���Y��P��,��u��W�<�T���;�7�LN�ϧ�����g�4�þ?�/y%�U�n�����b-a!
���z]�fP/�DR_�L>�T���c:	��ڳ�3���A��\;�e���?����m������Bp�W���N	�U�������PJ:���\�L��$!#夬,�d9�I���L�$�L�9�ʧ$��7~�N��������_y��s_W�+��Z�b��!��-���j1g�穥_��7w�T���۹��5�Lg����7H��B����/J�hR۳�U���Mk27S���ق�h�^(�k-����"-�ZZ+���YUD����V:��?>��xt���5�Iߣ�)����w<:	����8� ���&�x�����?���G����m��U��9ԲZ���5�.���f�9��r����B-�i
^k%���X;����q]S��	��]]��՘!g�ќTci���������ù���5l,Ye�=i������i��t�=���/�	��Wl�:��_����Q��+����������;n�'��A'a�e���T:��A���{d�i����-�qK<+Bo~���
���ѳ����(���Ye���hvY[�?���� b۞ݻ ��ri`�Sv��J�M ��`�K�b:�*�<��V�zo�􌜍m�h��\�گԊ��-tJ��L�k�Π��ް�r�M7�E�`�+??F�[۞��9�jc�'�q{�}7ԢW������= �~����lN�2>	v��MZd�IMk�Fi9�
R��w�k���	���5n��n�i0��S���v{R�����㛊���i��n��w�l]h�aP%���(&s�w}/s�Q����H-Tj&aeԻ��p���sS�O®���T�5ܹU/3C��>��ڊkP��zֻ�ީ�i4���?��ƫe����,C��?�f�l������k[�&.�pute/�5��i��@.��� ����EM������MWWuh_v!�xA'H�e��u���5mځ�ᜁP��n��� �
�m�ES�tSC��3�����*m�� ��2���ށ�h�sx�U k.��%زۂ�_]6�x�]@9��.�����a�@�l��ƀ.��B��N�	�r��S��'��_/ț�}�c�]DxS���_�zW��?J�S�������MT�9V�Nt8Pĵ 4Eɀ("=]���HE�Eh����	֖gG�ڳ�J PGy��0���`�qQN=��Ot��PC����hѶ�5.'�z���[@c�c����J(��[ ��ۇ'����t*_@oh?�^
g�
)~}%�����e���@�h|	���17z=$,�-h!�������.�g�z?n�\��k�;�.�˝�.���Gb��߾%�U(�߾�}��?�Q[����Q�.E�C/���<�~�֨��8!���
l�,��-��N��ho����W-���S�58C)��Eg[����(/�Ź�۹Q�M�:E]H�����.4�n�@�P��U�D��������� ���`�Ti@(�sˆ��5��m�j��&���'�:b�����ZbX���g����ߕ��)oy�{Am�ndyh�[?�%����%4�#!�<��kp�.*uS�+𹋯�D��|P}�>*C�k{��Ǫ�y��_;*ذ�f?`#֨qØ����A�"���a��=��@��I�/�t'��K��5�;|� ���F�}�1퉨e\��?�*/[��;��;INo�@�m���.�v�f�釄G�A�ֲQ;��}C?+���}C9"1y?u��q��t)j�ގ������9��Ƣ�v�/8��j��zŉ�a�b��%y��$���"����$C1O�&����A(�h��hc���;W�=�N��"�u*�-_,ݶ�^��ckX �|�
��Xؖ�#{��$'�7K�d��s���<������		��>G~"�&46�� .���j��&"��ߕ�܎R��;���+�[p��׉���������&�x.�N��T��� ��hh���O�E@�a0��9�=Z����A}�^@ۀ���"Y���v�2���d��R�-;��q�x���f]�JBWN�e���Bg t��X�,��{O�H|�R{Cᛩ�O��~AUa�c�4��j*��hQ���<�t
��j&��2T)%�R�HK)��V$UR��arP�3�3#��8��:˒i��	"f@�%p&����	�j<�	�����-�w��s�?ƒʋR&-J�D292��
ECF&ż(����Y2����()�La1�Z2��LRbF��a����/��\(���XZ�7�[͕��nYL^��m�.0����N�'�(c�|��O�ߓ����x��6;����$4�[��5K5a Ԯ(y���*ݞ�`����^���s���n]蕛�+,!�eݯ^��%�����Z�۪�"�]���P�<�>�"j`�;`�[�����n_���p����Iұ夆�:O
d�y_�*�����H�I���>�E���n�k'ۮXs[J�-�Q'�Gq</�i���/�/���"�����;��X�K��r��DЃ�|��4�f�1g���v��B��jV�+��W��d�Y�K�Nڞ�V	g[>�'q�H"��»y7��Bk"頞խ����r��㛍b�t�z�f�ZGow�Q��m�}���Ѩm�ȳRC���L"p����B	=���=!�[`{,�v�+��ʓ���|�ϗ\�N�զ�d��"]��9�*�ü��8�S.��C.�n^����T���$t��)����A�.we����/8��y�O��'��1��Jp+��4�Y����H��E"��h#�G�(���f��)�<�q,�B��
�m�SCE�.j�$�Dwt�Prq������ط�.m���bp3�L~��W�R������(*��?)�%4��@�-)�fR�	^�!��	T�v\ m۲�����.c�nN��s'p��)@�x�@����gC���?� 2}1��\�E)�v˞m��M�(�e����>~��?�N����?ėo��~��N�Ϸ3����/`�+�f۝x�̀w!@5�q��Y;.�<\踨�AA�b��=؇a�5�Ap���a0�azT�7e�U�����Z���
�����yE��/�x�O�f��i�p�`�4ⰛنJ8Y�$��Ux0��xh
+�^_]�s|��s`��+�����,��4��a��E���S�[��q���`?���������L���T�F�O��T��������T�<X�(=T�Xd#�����1�Y�=�q��a����`r�&0yd�^���da �a�������^��Hտ��?��P�X��<��,�Ѡ�H�6��*XG�W��h��mI&(��U0A�|��[�s���?07s㘇�/.6���\������R�/�,P�¸0J�;��_�� �g�aৡڃO]˶�_��{�d���Zє%6C�b�RW/���O'�O��]Pr�n"�����Ѹ3t�??�p틪L�z6`��e".�.#�DZ` ������]Q��@~�_1Y}2׻�������F�|0����,���01����v[��rp��E�{ڝ��;��� T83����p�a��`�:�w�LFu����B�����O��5\���(i1!��W˅��.%=#�%Hkb�E~p�{胃EhO|-�er��%`�i��ڦ�v��7ׇV(턨��FڦF.�Z�D����eUe`[��2*�Z�q�.;�+�V�������l�X���:�S���%���[:��r�\��ܬ�L��b'�	�~2�2W�]��b4��T��� ���f�M|=�C?��C3��(�è�0���c��0�
����RCE��|Q^�Q�^ͦ��i� �7h�8a������}�i��\Vvllm��4-�z������B�6�>(��FӇ6ڻ����e���B���syt��^��KC�Yb�H�Bc����f�z��Q��6����	]�]�p�6c)�ə����bv�[;����z~���� ꡕ��_H��=���3����Ջ���ؗ^�?�["y�*�� ���'�������%��ѫ�i���;�H��*�*�-�nhW���(�i��A��6��S�cT̶|�|�����-U9�ڟ�9�D'�;��2��%V��iT���C��]����I��`0��`0��`0��x����� 0 