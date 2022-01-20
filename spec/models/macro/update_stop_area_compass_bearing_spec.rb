RSpec.describe Macro::UpdateStopAreaCompassBearing do
  it "should be one of the available Macro" do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::UpdateStopAreaCompassBearing::Run do
    let(:macro_list_run) do
      Macro::List::Run.create referential: context.referential, workbench: context.workbench
    end
    subject(:macro_run) { Macro::UpdateStopAreaCompassBearing::Run.create macro_list_run: macro_list_run }

    describe ".run" do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do
          code_space short_name: "external"
          referential do
            journey_pattern
          end
          shape
        end
      end

      let(:code_space) { context.code_space }
      let(:journey_pattern) { context.journey_pattern }
      let(:shape) { context.shape }

      before do
        context.referential.switch
        journey_pattern.update(shape_id: shape.id)

        shape.update(geometry: "LINESTRING (7.091885616516534 43.57432715792825, 7.092105740785468 43.574444133071914, 7.092232913989094 43.57448386864411, 7.092297572624793 43.57451721573902, 7.0938826065460825 43.57495548692632, 7.094136957654024 43.57503495393627, 7.094338294145095 43.575071568446965, 7.0945759962426465 43.57509763689846, 7.0950863362075465 43.57512125399119, 7.095554590215809 43.57508352504564, 7.095602600334812 43.57506347285972, 7.095652755893213 43.57507037931442, 7.096488950614554 43.57498110270073, 7.096944842578117 43.57494388804128, 7.097292355099007 43.57494729754658, 7.097428315768137 43.57494157611041, 7.097690738820565 43.57496659774533, 7.097939371027158 43.57497416655492, 7.098088407276881 43.57497691033764, 7.0983814708545685 43.574919493893006, 7.098513137846123 43.57485985393559, 7.098762679794674 43.57472312144432, 7.099021002288743 43.57454093709573, 7.099040712595973 43.57447699307644, 7.099103228010209 43.57448337768834, 7.100330152274983 43.57353910368734, 7.100740550226401 43.57324231510663, 7.101092009824664 43.5729840724869, 7.101220805987493 43.57288848463423, 7.1013386741247295 43.57281138956969, 7.101373604913261 43.57278286931568, 7.101385964492778 43.5727823487464, 7.101631195062442 43.57259169282244, 7.101725059082929 43.572524624729226, 7.101893079940716 43.572454432830526, 7.102150481241803 43.57241654086251, 7.10264128008574 43.57235078276416, 7.103638099271019 43.57225468405201, 7.103921650219182 43.57223371876385, 7.104094682415194 43.57222642677747, 7.104128178758272 43.572179933338695, 7.104179765690291 43.572204808351444, 7.105717527158704 43.572049826878924, 7.106209752487999 43.57200202562804, 7.106320270144071 43.57198834955187, 7.106357348260733 43.571986786220215, 7.1063646905315325 43.57192336203557, 7.106455506486729 43.571973631123946, 7.108841029207871 43.57171974348565, 7.109948344057893 43.571609910580136, 7.110018913267295 43.57156185087887, 7.110047218153538 43.57160573850085, 7.110785903881678 43.57153850065361, 7.1115609481082265 43.57146070683157, 7.1118932118103615 43.57142864872937, 7.112066958285468 43.57143033067911, 7.112243575188683 43.571467956825956, 7.112845271142034 43.571704030101856, 7.1128597834999585 43.57173046661642, 7.112989835593698 43.57180612332657, 7.113119888016176 43.571881779887256, 7.1133029668383125 43.5720002793739, 7.1134998413250194 43.57213622888876, 7.113711947413057 43.57230760057275, 7.11390005376572 43.572489001838385, 7.114170214923513 43.572766118167685, 7.114612386123445 43.57333351114057, 7.114820756223184 43.57361323596496, 7.1150160505300315 43.57388449636501, 7.115378334304057 43.57438312987085, 7.115670924906319 43.574785525849705, 7.115864790507258 43.57503881259343, 7.115916384779965 43.575063682258, 7.117167720364126 43.57644442563267, 7.117439908484007 43.577677192783675, 7.117490919657579 43.57831520459275, 7.117497239447863 43.57854936504151, 7.1175655089945575 43.57862762811276, 7.117683939870782 43.578712787839166, 7.118342359033642 43.57903660327034, 7.118539268110332 43.57917254400725, 7.11887128493322 43.57944703686147, 7.119194537681956 43.57976698160772, 7.119625307116806 43.580190577808665, 7.119950005652763 43.580528492529645, 7.1195691245032195 43.58119377947312, 7.119546558641137 43.58122178278365, 7.11941691343287 43.581461691103286, 7.1191350535617515 43.581969510522164, 7.1190491005286844 43.58213543981624, 7.119020641462037 43.582244840158694, 7.119002387443007 43.58232675978759, 7.119115511591941 43.58265558692163, 7.119306977117187 43.58318848093194, 7.1193781295927945 43.58330268718069, 7.119380144365878 43.58348293108985, 7.119274640103884 43.58355952239513, 7.118948781824331 43.58367247679219, 7.118828040020473 43.5837136458811, 7.118593742977059 43.58388584440965, 7.118393655147325 43.58402053088002, 7.118304103775795 43.58414152922758, 7.118239994307667 43.584270468764, 7.118193276969012 43.58446178839365, 7.118204056805222 43.58459657953459, 7.118181344265671 43.58477786826864, 7.118191260741677 43.585056959030375, 7.118268162700677 43.58524305457996, 7.118319766769024 43.58526792314491, 7.118500021990512 43.58535046989993, 7.1186293920797175 43.58541713404056, 7.118635860668191 43.585498008698806, 7.11875186381501 43.58586278046773, 7.118818562686562 43.58607635632221, 7.118829344221871 43.58621114739924, 7.118872899817536 43.58629045461557, 7.11888885593677 43.58633486249333, 7.119120869972757 43.58706440537906, 7.119239754499541 43.58746512091534, 7.119273105639293 43.58757190870043, 7.119243206695902 43.58766333694961, 7.11924895750459 43.58773522550032, 7.119280871095234 43.587824041144934, 7.119235015228385 43.58787106157036, 7.119152790477655 43.587928635579345, 7.119000703079376 43.5880432609263, 7.118767827152879 43.58823343194039, 7.118674676367872 43.588309500211786, 7.11843001030228 43.588662464744566, 7.118330964228296 43.58881992982683, 7.118196985426743 43.589005920266956, 7.118006941137668 43.58926641109253, 7.11800909719016 43.589293369321695, 7.1180476231034975 43.58930977431553, 7.117985808862537 43.589312386240316, 7.116998324229732 43.59076968788881, 7.116833714077772 43.59103811826803, 7.116544602262852 43.59145607030598, 7.116321045220381 43.59176305538287, 7.1161884904684465 43.5919670156085, 7.116110567751758 43.59207850392817, 7.116088714596482 43.59211549263135, 7.116103233337296 43.59214192871998, 7.116054497961857 43.592153003501686, 7.115876797859568 43.59241296856392, 7.115817853890072 43.59245152366253, 7.115758191459752 43.59248109264043, 7.115773428530614 43.59251651486115, 7.115741366618365 43.59258098390631, 7.115705712742781 43.59260052249064, 7.115657695291519 43.5926205831919, 7.115609677808059 43.592640643872755, 7.1155471416649805 43.59263426837554, 7.115509332645859 43.59262684862397, 7.1154555683772145 43.59257502050663, 7.115427967941829 43.59254012034622, 7.115425812935167 43.59251316206983, 7.115332803311753 43.59243594191725, 7.115269549101334 43.59242058017396, 7.115206294923396 43.592405218395385, 7.11515684087386 43.592407306697254, 7.1150353605610865 43.59243948564144, 7.114421338961864 43.59267278918844, 7.113626884625271 43.59297682086045, 7.113360628655359 43.593060191302236, 7.113239864065228 43.59310135442551, 7.112288976613039 43.593466077464115, 7.1122045839006445 43.593496688086404, 7.112156564556596 43.59351674730308, 7.111899796648424 43.59356364811388, 7.111765230650333 43.59358735915249, 7.11172885708372 43.59359791036948, 7.111595008714108 43.5936306073212, 7.111509179892988 43.5936432451929, 7.11142406878362 43.59366486911683, 7.111327311536074 43.59369600075008, 7.111266927920872 43.59371658124366, 7.111037039189384 43.5937893951538, 7.110928635373042 43.593830034188606, 7.11061506928206 43.59394244297161, 7.110470290872823 43.59399363241528, 7.109786523252512 43.59413067125986, 7.109309352430646 43.59421391112536, 7.108943455898317 43.594292456484034, 7.108649590237274 43.59434091410442, 7.108502657228276 43.59436514262872, 7.108429907986172 43.5943862429555, 7.108346229296958 43.59442583683869, 7.107988937112405 43.594612212752544, 7.107869600147479 43.5946713424267, 7.1078339424562635 43.59469087853236, 7.107641138000128 43.594762121722596, 7.106914352492791 43.59498210349824, 7.1068677643432405 43.59502013276334, 7.1066224585408815 43.595210799942855, 7.10656350585294 43.595249350223206, 7.106505270117937 43.595296886620936, 7.106447034290408 43.595344422988674, 7.106412092749478 43.5953729447949, 7.106334147382843 43.5954844263799, 7.105869336858868 43.59618925936512, 7.105801603010404 43.59627326106637, 7.105582451351149 43.59648085618649, 7.10534143668897 43.596725437507224, 7.105204532400189 43.59687546792363, 7.105102570571674 43.59699697678361, 7.105118519325875 43.59704138659015, 7.104895778430022 43.59720404959579, 7.104780734000814 43.59731709295933, 7.104734142677208 43.59735512134487, 7.104604582692976 43.59744172698678, 7.104499034906897 43.59751830450363, 7.104320015504216 43.597606993446824, 7.1042363295914 43.59764658429104, 7.104140278868277 43.59768669594435, 7.104079888754086 43.59770727260487, 7.103804100323224 43.59782708608939, 7.10358798471123 43.59791733636987, 7.103324559106374 43.598036627875636, 7.10319284591006 43.598096273398696, 7.103073497257074 43.598155398015365, 7.102965796654792 43.598205015594864, 7.102882109009548 43.59824460543813, 7.10250004726741 43.59843200548577, 7.102141996538156 43.59860937676725, 7.10189164631554 43.598737130461096, 7.101736632958421 43.598815787890445, 7.101557605579346 43.59890447246551, 7.101438253698465 43.59896359535825, 7.101366928977388 43.599002663505445, 7.101283239158619 43.59904225216681, 7.10125994172113 43.59906126564193, 7.1012889694824155 43.59911414160917, 7.101223562974694 43.59907181348427, 7.100949195017438 43.599209592376006, 7.1006857584624585 43.59932887774198, 7.1004230370223835 43.59945714868078, 7.100243289637885 43.59953684499175, 7.1000875559251195 43.59960651397633, 7.099957268242139 43.5996841281107, 7.099851710552737 43.59976070129341, 7.099722854357669 43.5998562875363, 7.099573563598263 43.60000683152341, 7.099481086115399 43.6000918701785, 7.099447570535212 43.60013836221614, 7.099206516062918 43.600382930462416, 7.099091454772863 43.6004959680393, 7.099045573329409 43.60054298027611, 7.098867252739504 43.600640646789934, 7.098518679837356 43.60078154153402, 7.097747336389606 43.60106644886255, 7.097396611174243 43.60118038154619, 7.097188545078644 43.60121618224989, 7.0970772556641455 43.60122086319872, 7.096768833948118 43.60124285146912, 7.096395006562724 43.601222507989554, 7.09539595317924 43.60098501301731, 7.095332695051505 43.6009696401447, 7.09517051333276 43.600958426409896, 7.095059939617797 43.60097209159563, 7.094899904005131 43.60098783613106, 7.09480169563992 43.60100098120235, 7.094644521146745 43.60105267026032, 7.094572474193273 43.601082747905814, 7.094212953593337 43.60124212167036, 7.093996095957826 43.60132336741979, 7.0938039688491425 43.60140357327246, 7.093682458790825 43.60143572930926, 7.093453234149091 43.60151749374732, 7.093283691537738 43.60156970061981, 7.0931388798476505 43.60162086790222, 7.093054465837798 43.60165146425076, 7.092789572699817 43.601752758784194, 7.092793147934387 43.601797689950985, 7.092779352195609 43.6017802371152, 7.092270719476368 43.60193685394484, 7.091734280535001 43.6022118481615, 7.091730493505831 43.6023202025566, 7.091672953990426 43.602376717560304, 7.09160090394878 43.60240679331508, 7.091453229377182 43.60242201347889, 7.091325282473699 43.60237329081161, 7.091297691595116 43.60233838478139, 7.090994980268079 43.602432247273704, 7.09067489900838 43.60246372463302, 7.089074982787119 43.602783369709314, 7.089089492179763 43.60280980925218, 7.08907784079195 43.60281931473556, 7.088696641392217 43.60286236887675, 7.088460260367821 43.60285426061993, 7.088322806634691 43.602841998762614, 7.088223165033909 43.60283716560802, 7.088121380374821 43.60280537357804, 7.087087378437999 43.60259632149661, 7.085816777221566 43.60253243178796, 7.085606557565554 43.60254125238784, 7.08551048649743 43.60258134823982, 7.085404191260799 43.602648921675254, 7.0852600841475715 43.60270906516507, 7.085147363204153 43.60269576183345, 7.085053433268775 43.6027628161417, 7.084937626783748 43.602866853053264, 7.084877938710162 43.602896405757086, 7.084767842513027 43.603072332758316, 7.084544561884356 43.603541526873556, 7.084374060542861 43.603738019700074, 7.084314371321795 43.6037675721063, 7.084253254464425 43.60377915190761, 7.0837353041728885 43.60381890868113, 7.08347775611437 43.603856758763136, 7.083344583016044 43.60389840861597, 7.083132696353522 43.60404253761191, 7.082985494215459 43.60422001860178, 7.0828658780965545 43.60443240748792, 7.0828658780965545 43.60443240748792, 7.082565525013834 43.60486876376834, 7.082417605632524 43.605037257719516, 7.082383360499582 43.60507475840407, 7.082322955447253 43.60509532346192, 7.082189065293454 43.6051279856566, 7.080639693779273 43.60514785285309, 7.080444683551186 43.60519209080494, 7.0803129317970255 43.605251709713556, 7.080044192756229 43.60546132843975, 7.079938599390256 43.60553788305493, 7.078733316236502 43.60598509730121, 7.078311177706045 43.60613802472761, 7.077447150273773 43.60650781507783, 7.07677456723003 43.606788435866655, 7.076570032650523 43.60686913036283, 7.076484177446177 43.606881741691424, 7.076004720865016 43.60693788222894, 7.075967620296386 43.60693943562067, 7.075659161351636 43.60696136641936, 7.075475541665299 43.60714937725642, 7.075413452751474 43.6073052514883, 7.075205809756036 43.60750328369491, 7.074786701563655 43.60800770077359, 7.074670154672037 43.60810274082973, 7.0744663251315405 43.6081924178714, 7.074116938457191 43.60832425115584, 7.073861243393477 43.60854232395431, 7.073685448065637 43.6088291817424, 7.073662332536416 43.60916374694818, 7.0736892040060395 43.60918967091415, 7.073653526502443 43.60920919625186, 7.073597776092539 43.60991478958189, 7.073657930110116 43.610047514704426, 7.073448135057554 43.61021858461948, 7.073354180197855 43.610285629214125, 7.073145807840835 43.61047467127568, 7.073032814456035 43.61061464141608, 7.0728763080625585 43.61067528661499, 7.071974366253879 43.61103760119474, 7.071662060775619 43.611167874815074, 7.071422984134831 43.611439342952245, 7.071241026345492 43.61149203412079, 7.071433052359894 43.61234955236196, 7.071543388168568 43.61248919575142, 7.071837821461095 43.612603106291445, 7.0722721277268095 43.61260297113156, 7.07265313952418 43.61271325777724, 7.072826031563044 43.61285929908978, 7.072980337369084 43.61324053778693, 7.0731056352289015 43.61356889311207, 7.073551086074231 43.61386582022949, 7.073627173867859 43.61404295957907, 7.073670430906612 43.61427556961918, 7.073669459693239 43.61441986877541, 7.07367444597663 43.61448277323036, 7.073618043320299 43.61471053725143, 7.073654177512431 43.61485328378375, 7.074095563051273 43.61541184800246, 7.074439688780901 43.6158392387503, 7.074514356773366 43.61599840480309, 7.074509112735191 43.61608878588938, 7.0744448746328334 43.616217700516444, 7.074292629658126 43.6163322657339, 7.0741011403420275 43.61642142448485, 7.0739803015850375 43.61646254572385, 7.07353333920581 43.61661649045754, 7.073281427942292 43.61672620815524, 7.073245745810397 43.61674573336039, 7.073209351370956 43.616756272201236, 7.072897018724602 43.616886549203855, 7.072728126829584 43.61694771164635, 7.072569466983881 43.61698139734242, 7.072313991647527 43.61704618110361, 7.072216464096101 43.617068292948936, 7.072131305460988 43.617089887334664, 7.071922456818562 43.617116655259274, 7.071602999001098 43.61715706508397, 7.071333728829455 43.617204391226736, 7.071111798429322 43.61722268858109, 7.070964794023989 43.6172468683985, 7.070916029844318 43.61725792375104, 7.07086797758512 43.61727796545016, 7.070843951443446 43.61728798629209, 7.07089698731865 43.61733084917502, 7.070925997103477 43.61738373289237, 7.07094263786931 43.617437133849485, 7.070934540501838 43.617491569298146, 7.07085507631706 43.61758505366115, 7.07080702377464 43.61760509533423, 7.070759683126488 43.61763412335509, 7.070635991988671 43.61763929555372, 7.070560353502261 43.61762442606929, 7.070442624571803 43.617548203526965, 7.070386029484943 43.61746040857895, 7.070382470145763 43.61741547672608, 7.07034251548725 43.617381082792974, 7.070289479964831 43.617338219650605, 7.070034980667285 43.61725869915869, 7.069818300906474 43.61718661310397, 7.069588540908084 43.617106057358654, 7.068841249195106 43.61675861884521, 7.06860935738008 43.61665110197217, 7.068454526110617 43.616576428332046, 7.068274957427665 43.61650278839376, 7.067994303596926 43.6164063244567, 7.067880849205164 43.6163840175655, 7.067765971974659 43.61634373778611, 7.067501957089034 43.61630067405211, 7.067275760544904 43.61626504556056, 7.067213916243629 43.61626762977554, 7.067026960608485 43.61625740943408, 7.066802898456891 43.616248739174516, 7.066616654238576 43.616247504549506, 7.066443490152613 43.616254739259276, 7.066257957156882 43.616262490440384, 7.066084792984157 43.61626972460203, 7.066022948626606 43.616272308167034, 7.065999633272629 43.61629131438047, 7.065977740288674 43.61632829338612, 7.065917318233119 43.616348849690525, 7.065868553852773 43.61635990287137, 7.06579291816942 43.61634503020435, 7.065755100341848 43.61633759385194, 7.065704913636927 43.616330674162455, 7.065567433606361 43.61631838470264, 7.064977993111628 43.61639710125195, 7.0647080101172035 43.61643542524732, 7.064291021514902 43.616497919759986, 7.062871149075853 43.61674654184284, 7.0604055767911404 43.61711091062584, 7.060038055425692 43.61717132509085, 7.059804462855313 43.61719910279229, 7.059794934834327 43.61723556457081, 7.059785406801722 43.617272026348516, 7.05975114047661 43.617309520178175, 7.059703794697546 43.617338543580466, 7.059617210662837 43.617342155686565, 7.059529206145804 43.617327794849146, 7.0595023371575865 43.61730186753146, 7.059488547557635 43.61728441065074, 7.059282533374879 43.61734710103597, 7.059099836749944 43.617390786258234, 7.058893821793429 43.617453475936586, 7.058796998745808 43.617484562674996, 7.058784629560618 43.61748507859523, 7.058288853607983 43.617650013305514, 7.05785421123909 43.617803380323465, 7.057589186986727 43.61790459250014, 7.057211418287477 43.617992472937175, 7.057198339090147 43.617984002231196, 7.0571905302764275 43.61788515124627, 7.057196811649769 43.61765047197063, 7.057211611636777 43.61752363013163, 7.057193864456926 43.61729896880005, 7.0571577680695645 43.61715621703229, 7.057115691576883 43.617094859075095, 7.057086694142361 43.61704197182278, 7.0570322487068555 43.616981129567975, 7.056977803382112 43.61692028728691, 7.056899329858827 43.61686946286498, 7.0567954085206495 43.61681068334046, 7.056548329993502 43.61666771166571, 7.0564139932282135 43.61653807147724, 7.0563291329805535 43.6164063685336, 7.056219432697219 43.61596013943686, 7.056215477991244 43.615752935221025, 7.056235247634273 43.6156889987217, 7.056344741226456 43.61550411305951, 7.056390667698875 43.61545711814134, 7.056401616998071 43.61543862956479, 7.0564242253225435 43.61541063886714, 7.0564365940991305 43.61541012320454, 7.0565524744306005 43.615306115467575, 7.056622428300632 43.615249102642856, 7.0566800133080205 43.61519260546542, 7.056734759047061 43.61510016243148, 7.056801873307019 43.61500720366831, 7.056818802875892 43.61490732124003, 7.056859050075336 43.614788434480296, 7.05686786969073 43.61474298648997, 7.056833195220279 43.61461820752033, 7.056799230686436 43.61450241499618, 7.056571220751565 43.614286520301526, 7.056518197841378 43.61424365071097, 7.056208578342681 43.61409427017029, 7.05608276422942 43.614072467103725, 7.055994055705474 43.614049117058464, 7.055833265202029 43.61405581993969, 7.055697211670971 43.614061491430235, 7.055550918405779 43.61409463771796, 7.05540391540046 43.614118797351416, 7.055281649325251 43.61414192572232, 7.055184120215156 43.61416402291074, 7.05513464609498 43.6141660850064, 7.0551353556330865 43.61417507147348, 7.0551106185680155 43.61417610251335, 7.054902481990525 43.61421182553995, 7.054829689720653 43.614232891428834, 7.054668189123996 43.61423060618789, 7.054592558918439 43.61421572604452, 7.0545169287505125 43.61420084585066, 7.054376618217207 43.61415259692995, 7.054298859946489 43.61411075717504, 7.054196364747622 43.61406994820707, 7.05415713102054 43.61404453503779, 7.0539730220144445 43.61407023905249, 7.0539359164515005 43.6140717852297, 7.053618679453423 43.61445466117252, 7.0534939735255815 43.614604113640496, 7.053403535835549 43.61471607406794, 7.053346657468992 43.61478155605923, 7.053300019853591 43.61481956326619, 7.053273552801133 43.61495590640142, 7.053291595674697 43.615027282909935, 7.053308929316535 43.61508967293716, 7.053390943892305 43.6151854322366, 7.053482490293841 43.61524473022745, 7.053584277700246 43.615276553363266, 7.053686774548987 43.61531736288351, 7.054075172403537 43.61536429129057, 7.054226435499217 43.61539405221647, 7.054326804692329 43.615407901740326, 7.054465699224325 43.61543817777917, 7.054528252679948 43.6154445869919, 7.0545536997455045 43.61545254254956, 7.054616962701142 43.61546793818369, 7.054630750460623 43.6154853956581, 7.054706382280979 43.61550027577543, 7.054874981455487 43.61559242564544, 7.054996943908209 43.61572258316869, 7.055058481585415 43.615873291074905, 7.055057465447756 43.61601759006104, 7.055017213840617 43.61613647617659, 7.054957900435303 43.61632828502378, 7.054885508101736 43.616511622865566, 7.0548452558203785 43.61663050891833, 7.054813517623777 43.61685723257732, 7.054853155882743 43.61704491743343, 7.055009793326055 43.61729985450345, 7.055094651936324 43.61743155843158, 7.055103876373754 43.617548382494945, 7.055108133818565 43.61760230129306, 7.055042433146625 43.61771323197939, 7.054962943831437 43.617806705196145, 7.054916304884338 43.61784471306495, 7.054868246793844 43.61786474797897, 7.0546986241891965 43.617916897079915, 7.054267826572445 43.617961897242296, 7.053935273584202 43.617993786213965, 7.053925741858944 43.618030247498076, 7.0538791020784855 43.61806825493974, 7.053871698492044 43.61813167564084, 7.053867132471343 43.618231042237106, 7.054084506217014 43.618312145260155, 7.054200087460272 43.61836142537771, 7.054439363035655 43.6184055509922, 7.054590634003455 43.618435311429316, 7.054715037697862 43.61843914321267, 7.055209814234238 43.61841852311863, 7.055768871261133 43.61826899687242, 7.055950153583667 43.61820734409965, 7.0563621944277966 43.618081975074006, 7.057088435115912 43.61800661680185, 7.057223077694018 43.61798297073569, 7.057490942657435 43.617917705220805, 7.057611085733477 43.61786761511703, 7.057768336396727 43.61781597746599, 7.058202979077339 43.61766261077747, 7.058237956620398 43.617634103863054, 7.058359518627321 43.617601985858826, 7.0591348137066285 43.617362279066775, 7.059353907447558 43.61730805940901, 7.059474757965732 43.61726695376835, 7.059458837709219 43.617222537566754, 7.059468365933007 43.61718607581647, 7.059491683710943 43.61716707094742, 7.059502632364647 43.61714858207216, 7.059538319222364 43.61712906119491, 7.059574006056789 43.617109540306394, 7.059622772211254 43.61709848983452, 7.059723855776022 43.61712132101562, 7.059750014512411 43.61713826184353, 7.059791383464256 43.617190632385395, 7.059864887870288 43.617178549747756, 7.063037918214672 43.61665843484031, 7.060283306534039 43.617134044391314, 7.06327435033232 43.61666659613499, 7.0646956411999655 43.61643594181276, 7.064780801588032 43.616414353014356, 7.06547800693265 43.61628605568226, 7.065587904573318 43.61626343297423, 7.065705904094602 43.61618637508324, 7.065740166043732 43.61614887945185, 7.065824614478891 43.61611830346876, 7.06591190754725 43.61612367301882, 7.065912618727667 43.61613265941781, 7.065975174135492 43.61613906231159, 7.066015836649691 43.61618244418402, 7.066204214327837 43.61621063898796, 7.0670969056070545 43.61620039014534, 7.067484608292955 43.61623828619894, 7.067925344318777 43.616319045201, 7.068422672653299 43.61648759844827, 7.069041998971823 43.616786291913385, 7.069543604752467 43.61700875851368, 7.069683934217227 43.617056988649786, 7.06974720276303 43.61707237583625, 7.070283785152384 43.61726632868078, 7.070485249181696 43.61730298556311, 7.070508563504701 43.61728397842741, 7.070605380140152 43.61725288168287, 7.07075380854728 43.61724667506826, 7.070883906328101 43.61732238004846, 7.070955718893271 43.61744560296919, 7.070902416880085 43.617556025600386, 7.070832473923964 43.61761304723567, 7.070735656823612 43.617644144173944, 7.070598884643155 43.61764084718699, 7.070547272495172 43.61761595690397, 7.0704250051288335 43.61763910161133, 7.070122895457307 43.617741894663304, 7.069574824919625 43.61787300187328, 7.069055048761698 43.618048004248365, 7.068744123583279 43.61819624255725, 7.067936455283302 43.61865375601722, 7.066931298598019 43.6192818046871, 7.06662534103044 43.619492941919056, 7.0647658034415475 43.62061648203063, 7.064673244613761 43.62070149221635, 7.064565471570909 43.620751073252926, 7.064224804640467 43.620837427403735, 7.064055892722393 43.62089857691376, 7.06403470780579 43.62094454194821, 7.063953806360488 43.621020048642904, 7.063844610290249 43.62105165617355, 7.06369474991269 43.62103988091462, 7.063578444783884 43.620981624072684, 7.063534937253225 43.6209022956815, 7.063380101314691 43.62082761511791, 7.06312033469309 43.620838459663126, 7.0629704749923015 43.6208266834464, 7.061190636841435 43.620919000501615, 7.061190636841435 43.620919000501615, 7.060463655540322 43.62098539862386, 7.0601696195085175 43.6210337304361, 7.059914823774444 43.62110747266946, 7.059526799160665 43.62122283616432, 7.059013356355841 43.62147867040113, 7.05883490800151 43.62157627383546, 7.058602420427998 43.62177530737585, 7.058442021624455 43.62194428583575, 7.057823848743975 43.622916750179456, 7.057591762475461 43.62327805351291, 7.057334631666929 43.62379367331519, 7.057165101895136 43.62416138339233, 7.057154151235048 43.624179872037736, 7.057120997868773 43.624388623387155, 7.05713164725856 43.62452342016405, 7.057211550968863 43.62459221731564, 7.057243392091 43.62468105032777, 7.057234571295384 43.6247264983336, 7.057200299100207 43.62476399138328, 7.05712962468786 43.62481201809646, 7.057032078860834 43.624834116868136, 7.056876228963125 43.624903726392716, 7.056690365446073 43.625064747322924, 7.0564250039132315 43.62531924216805, 7.056277670159317 43.62549668833898, 7.055614504839041 43.626371836428085, 7.055433601469837 43.62659576051411, 7.055305326196623 43.62670028261093, 7.05516113087144 43.62676038777007, 7.0549900639597 43.62679456436582, 7.054093355708679 43.62691307088027, 7.05395798227609 43.6269277267503, 7.053910626071461 43.62695674772346, 7.053786204711015 43.62695291505797, 7.053467391546207 43.627002260216834, 7.05319735330367 43.62704055677552, 7.0529870427072385 43.627049316842715, 7.0529135247803225 43.62706139501535, 7.052824798227792 43.627038042498356, 7.052724409864345 43.62702419164901, 7.0526473453306044 43.62699133725591, 7.052583361385988 43.62696695404811, 7.0524843917807125 43.62697107594517, 7.0524341976887985 43.626964150380836, 7.052357133391854 43.62693129579035, 7.052316473477804 43.62688790903189, 7.052286057018666 43.62681704760492, 7.052255640631611 43.62674618616964, 7.05219764505069 43.626640409202196, 7.0521541484996275 43.6265610764569, 7.052072120304578 43.626465316295786, 7.052044541224865 43.62643040073448, 7.051978430499283 43.6263790577356, 7.051913029085403 43.626336701181955, 7.051784354069444 43.62627894741539, 7.051176360989663 43.62612394354609, 7.050960380898668 43.626060807944356, 7.0507698523160425 43.62600562833569, 7.050369335597177 43.625805918222916, 7.050106319725836 43.62561851507368, 7.049834798999228 43.62532327334732, 7.049705030820331 43.62509425882854, 7.049657285637939 43.624961006132544, 7.049591819877388 43.62460309094542, 7.049564951928892 43.6245771612776, 7.0495889845631945 43.62456714494973, 7.049598840599758 43.624377398639666, 7.04960695831811 43.62432296472893, 7.04963060255496 43.62415067649393, 7.049660626142772 43.624059266741035, 7.049658499645127 43.62403230724512, 7.049619970137323 43.62401587901126, 7.04958214947105 43.624008437263456, 7.0495181699672305 43.62398405232297, 7.049489884716722 43.62394014963777, 7.049474678902154 43.62390471854271, 7.049472552493821 43.62387775904315, 7.04932726186817 43.62376659838513, 7.049213091717864 43.6237352863091, 7.049074180576913 43.62370500383983, 7.048911237191443 43.623684737389794, 7.048823225913283 43.62367036824123, 7.048723552816516 43.6236655003508, 7.048539411859871 43.62369119552979, 7.048404752999128 43.623714831274405, 7.048246770126511 43.62375746941503, 7.047967915485491 43.62384120082508, 7.047761866644283 43.62390387025315, 7.047590803675469 43.623938035684176, 7.047394290769846 43.62396424369938, 7.047220393556408 43.62396246251993, 7.047007967609155 43.623944251951805, 7.04662976507321 43.62386982518918, 7.0464109645556015 43.623770734843006, 7.046271346431353 43.62373146241944, 7.046183335718732 43.62371709122086, 7.04599636039785 43.623706836186116, 7.045781810994222 43.623661663754696, 7.045718541646436 43.62364626319208, 7.045684262851517 43.623683752760314, 7.045600501659399 43.623723300250596, 7.0455510193017705 43.62372535816143, 7.045488458147882 43.62371894399481, 7.045437559401337 43.62370302880651, 7.045398323077081 43.623677612612184, 7.045371457362415 43.62365168194951, 7.045174236271002 43.623668899590065, 7.045125462090565 43.6236799438419, 7.045100720921941 43.62368097269631, 7.0450883503373065 43.62368148712149, 7.044977723190876 43.6236951034154, 7.044891129066121 43.623698704269366, 7.044856141615359 43.62372720705852, 7.044786166613796 43.62378421260439, 7.044694990657437 43.6238871795207, 7.0445921518047925 43.62399964726457, 7.044514761983163 43.62412007272459, 7.044450450607902 43.624248970308315, 7.044408048235 43.62434089303114, 7.044371310072164 43.62450470799057, 7.044361437429939 43.624694453844825, 7.044369265914749 43.62510886298429, 7.044305661204864 43.62524674701316, 7.044261133791854 43.6253117100829, 7.044215190221575 43.62535870007038, 7.043978391314731 43.625503784390546, 7.043468721214507 43.62565119545614, 7.043420653016795 43.625671225510466, 7.043007824910177 43.62578756091038, 7.04288623802356 43.62581966243809, 7.042678053625872 43.625855362998166, 7.0421605923061055 43.625903916220416, 7.041774966036224 43.625892893181586, 7.041598940453111 43.62586414373479, 7.041536377485898 43.62585772738706, 7.041510927725017 43.625849768908836, 7.041459320601991 43.62582486538599, 7.040874685904279 43.6256508050963, 7.040748853072512 43.625628985012774, 7.040523344676003 43.62560228968774, 7.039838693930117 43.62557663422947, 7.039650299191137 43.625548395606806, 7.038875157041816 43.6253191263796, 7.038760989400986 43.62528780377633, 7.0385559820421495 43.62520615766878, 7.038399751852347 43.62511346985434, 7.0380837574071045 43.62488316072517, 7.03774090255123 43.62462691824278, 7.037561347527111 43.624553229659476, 7.0374224403874885 43.624522932910224, 7.037347508447446 43.624517027837065, 7.037296611188316 43.62450110899316, 7.037244300011681 43.62446721697428, 7.03722910131767 43.62443178423732, 7.037225566473393 43.624386851356405, 7.037247480182947 43.62434987791693, 7.037208246914997 43.624324458887926, 7.037182091421555 43.624307512861, 7.037138616485057 43.62422817434872, 7.03733301380337 43.6241750243895)")

        journey_pattern.stop_areas[0].update(latitude: 0.43574325e2, longitude: 0.7091888e1)
        journey_pattern.stop_areas[1].update(latitude: 0.43575067e2, longitude: 0.7095608e1)
        journey_pattern.stop_areas[2].update(latitude: 0.43574477e2, longitude: 0.7099041e1)
      end

      context "Update stop area compass bearing" do
        it "should compute and update compass bearing" do
          subject

          journey_pattern.reload
          expect(journey_pattern.stop_areas.map(&:compass_bearing)).to match_array([62.0, 96.4, 125.7])
          expect(macro_run.macro_messages).not_to be_empty
        end
      end
    end
  end
end
