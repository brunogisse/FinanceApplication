object frmFornecedor: TfrmFornecedor
  Left = 0
  Top = 0
  Caption = 'Cadastro de Fornecedores'
  ClientHeight = 552
  ClientWidth = 855
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PainelTopo: TPanel
    Left = 0
    Top = 0
    Width = 855
    Height = 265
    Align = alTop
    TabOrder = 0
    object btnNovo: TImage
      Left = 6
      Top = 12
      Width = 33
      Height = 33
      Cursor = crHandPoint
      Hint = 'Inserir nova Conta'
      ParentShowHint = False
      Picture.Data = {
        0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
        0020080300000044A48AC60000000467414D410000B18F0BFC61050000016850
        4C544500000000274E002E53022E52012D52012E52012E52002D520037490033
        52022E53012E52012E52022D51002F51003955022D52012E52022E53002B5501
        2E53012E52003050012E52012E52002D4F012E520536591153734ED0E055CCDD
        4ED1E14DD0E14DCCDD4DD0E14DD0E100FFFF4BD2E14DCFE1012E522E90A9002E
        51012E52012E52012E52012E52012E52022E53022D52002E51002D51012E5200
        2E5D022F52002E55022F53022E52002449012F52012E52002B55002C4E012E52
        012E52002E51002F53022D51002D53002B55002F53012E52012E52073A5D0F4B
        6C175D7B0F4C6C073A5E0B4465267F993FB2C64DD0E127809B073B5E2C8BA54B
        CCDE083C5E12527246C0D445C1D31252711B64824BCADD1F6D894CCFDF267C97
        267D9737A2B8339AB137A1B8237692175C7B277D98277E98165B7A4DCFE0063A
        5C3EB0C50B436438A3B92C8AA32B89A245C0D21150711A64811A6380104D6D44
        BDD01251712B89A3000000DB2EDD6B0000004774524E53000D599BCAEAFA5A0E
        1997F5F69D260982F48B24D2D130E9E82DACFE78D90F8AF71E91E4013370EBB1
        16F9D6F8C9C79A985855F30B9921888507C5C30617E2E12C2B87220C56C802F3
        F5B000000001624B47440088051D48000000097048597300000EE900000EE901
        0E33421C0000000774494D4507E408010B3A29A2837664000001EA4944415478
        DA7593EB4F1A4114C5CF59779165A5D212C192624D636B43DA6863823191A48D
        F6EFE64369D2681F3E628D4AA922820AD2FA688A05763BCBC2EC50BB37D9CCE4
        CE6FE7BECE10D2D833388EA3B3E57B071B935C96DEF7E4D530304E66BD4BC4D7
        16BBFC58F75201E25C0042EEB16B8ED6F9037CB62F2490E03C2CB22343E88E76
        854DD6FA405C9F17316EA15A984D6C573D60DC5810317E61D82CE659F180D8A2
        60FE3D77ED13CB2E6086B396718BFFD997231788E430D61DB8A2A47D2D810D7E
        1755479643A332FF580D0F7FFA576C9540ED2D4635E9B95F45EA870F6CB3C891
        55515210809D03EA2B0C2310F8BACFD969DDF0F2331C40ABE0912D526F7B9946
        D7C94C3ADDF0E675AAFC3955EFFB2A3E30515680C7E7BD257978A28418A10CE1
        74BD10EDCE065FA682939C64A9C6B9C9E03253DF70C65789E046258E50775B3D
        73A6B6FA6945CA26596C089189563E3B96C30AF3B71CD6D41E9AEB44FCFA8D15
        F265AE94BAE79C44D6447E8B313CD0EE0AC69AD8C5E50757514B8C22737E4772
        C91DDCB0D0136D8E265EB0387C7F680B2DFB5D5FF6AF6D1346A6A4C83EB5EFA0
        A5E5317838B96E149869EB55AF3F1D435C77D3DC8504B0649EA6C5F2E4503CDE
        E992D81DDFD30B500060A551CECA100D8D6BFDAD3F06ACB29ED88CE362AEF05C
        FB28BD7F01F3179B7C1597AECA0000002574455874646174653A637265617465
        00323032302D30382D30315431313A35383A34312B30303A3030AB713BED0000
        002574455874646174653A6D6F6469667900323032302D30382D30315431313A
        35383A34312B30303A3030DA2C83510000001974455874536F66747761726500
        7777772E696E6B73636170652E6F72679BEE3C1A0000000049454E44AE426082}
      ShowHint = True
      OnClick = btnNovoClick
    end
    object btnCancelar: TImage
      Left = 45
      Top = 12
      Width = 41
      Height = 35
      Cursor = crHandPoint
      Hint = 'Cancelar opera'#231#227'o atual'
      ParentShowHint = False
      Picture.Data = {
        0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
        0020080300000044A48AC60000000467414D410000B18F0BFC6105000000E750
        4C5445000000022E52012E52022E52022E53022F52012E520940621B64824DD0
        E156444DFF7043EF6C4481504B323B4F0C3151333B4F82504AC05F46163351CA
        63460A305111325149414E48404E0F3151CC6346FC70432D395062474CF16D43
        F96E434D414E2E3A50FD6F43B75D47FE70434F424DB95E48754C4BCE63461B34
        51A45848774D4B5C464DF86E43D86646F76D445D454C6A494CDB6646E168456B
        4A4C9D574985504A9F5749ED6B44103251BB5E4709315112325193544A413E4E
        9C574959454D032F52985649764C4B794D4BB15C48303B4F313A50B45D47DE68
        45B65D471D35500000000C6A8F1F0000000674524E53009CFC9B9A9945DB7AFE
        00000001624B47440088051D48000000097048597300000EE900000EE9010E33
        421C0000000774494D4507E408010C0A2F91E9F3270000010A4944415478DA95
        D3CD4B02411806F0E7B155F1201A08057AD0A40F348B3C8488081EFCAB3B1445
        8844605408A69448858107F5242E4E3352A7999DD13DCCCEF2FC78877D5F8670
        3C7402D2B3C43E19F2AC057C466491C058084810B280D546C07984E33737009E
        E5087F4B20DB4AB92C45008872BE7EC7C5C208629C22296B4C90084F0D20C91F
        EC7192E21790E65807FB23ECC6BF5391A1FAC87EEA20F38E8391CAF3ECE3F043
        07B91E8E672A0FB38BC29B0E8E5E713A57F9E0E419675D1D149E901FA81CC50E
        2E5E7450E223D6F9391F2E3BC2D087721BA8A84EDEA3D63676B272F7B7A9B702
        6651E58D5C1BFC878669D60971BBF5B89BD781A07105F7C5F156D6ABB7E3BEBC
        2EF00B70F964BD9617B2570000002574455874646174653A6372656174650032
        3032302D30382D30315431323A31303A34372B30303A3030D665516F00000025
        74455874646174653A6D6F6469667900323032302D30382D30315431323A3130
        3A34372B30303A3030A738E9D30000001974455874536F667477617265007777
        772E696E6B73636170652E6F72679BEE3C1A0000000049454E44AE426082}
      ShowHint = True
      OnClick = btnCancelarClick
    end
    object btnSalvar: TImage
      Left = 92
      Top = 12
      Width = 36
      Height = 35
      Cursor = crHandPoint
      Hint = 'Salvar opera'#231#227'o atual'
      ParentShowHint = False
      Picture.Data = {
        0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
        0020080300000044A48AC60000000467414D410000B18F0BFC6105000000AB50
        4C5445000000002C4F012E52012E52012E52002D51002E51012E51012E52002E
        55012E52022E52002C51012E52022F53005555022D52012E52002D51002F5401
        2E52003155022D51022E53003050012E52022D51012E52012D52003053002E52
        012D51012E520F4C6D1B6482125272114F6F0F4C6C4CCEE04DD0E1339AB14BCC
        DE19607E19617F0D48680230533FB2C747C3D5349CB3359DB41C668405365905
        375956444DFF70431D3550000000CD7D2A900000002074524E53001DACF2F34F
        16D8D727EDA745E5AA0382C65546E82A9D9A20C78DF0AE251CF1D486B4420000
        0001624B47440088051D48000000097048597300000EE900000EE9010E33421C
        0000000774494D4507E408010C0D2C47A1345A000000FE4944415478DAD5D35D
        4FC2301805E0735A3B860151440CD111FEFFCF122F260B662A4C97CED5D96DAE
        05E6B59E9B367D9F7E26254846C023351070813631DF6D4B0EE7B693EC81D10C
        5DB6851514CB0AA1C4F32B3061590DC909A411452328235581DC823AD30B8446
        30AB0557100A1604E3E2E50740883D764C5C3058A469075AE18055B34D031AE1
        0019651B17E0FB1CB103D494B1072074E19EC1BB45DDD56507F2BC0561701278
        39066AE7D6C7CC0F41C80F0704ED821DE8C9DF02E74C0F6A972673C1687B347B
        F6F6CB4BDA0C7C7043AF6A927F05DA8F730A18A335EFCFA03EABAF775B7A403C
        41406A3C70C839FAB3B92696E9157BCA667DB7FE0263E0A3F8D4C9BD55000000
        2574455874646174653A63726561746500323032302D30382D30315431323A31
        333A34342B30303A30300CBAF0F10000002574455874646174653A6D6F646966
        7900323032302D30382D30315431323A31333A34342B30303A30307DE7484D00
        00001974455874536F667477617265007777772E696E6B73636170652E6F7267
        9BEE3C1A0000000049454E44AE426082}
      ShowHint = True
      OnClick = btnSalvarClick
    end
    object btnAlterar: TImage
      Left = 134
      Top = 12
      Width = 35
      Height = 35
      Cursor = crHandPoint
      Hint = 'Alterar Conta selecionada'
      ParentShowHint = False
      Picture.Data = {
        0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
        0020080300000044A48AC60000000467414D410000B18F0BFC6105000000F650
        4C5445000000002851002D52002D51002F52000080002F53012E52012E520030
        50002F52012E52012E52002B55002E51012E52002C50012E52002C4E022D5201
        2E52012E52012D52002D51022D51022F52002F53012E52012E52012E52012E52
        022E52002E55012E52002D50012E53003050022E52012E52002D53002F530039
        55022E52002F53002D51002D51002E5D012E52175D7B28829C093D601F6C884C
        CEE04DD0E144BDD00B42641F6D8942B9CD0A416341B6CB023055073A5D267B96
        277D980F4C6D0F4B6C25799406395C4BCDDF03335645BFD20E496A46C2D538A4
        BA37A1B838A3B90D486845C1D3277E982E8FA821718D000000C750F2A7000000
        2F74524E5300135A6B410262F4CD2067FEE3246EE223E11798E7F7CA55878947
        FDC3F6EDA521EC33EE308CD7665C09967277650B62E24A2700000001624B4744
        0088051D48000000097048597300000EE900000EE9010E33421C000000077449
        4D4507E408010C19307D0EBF40000001184944415478DA85925D4FC2301486DF
        3721C4115800D12801346617FEFF9FE285C618231ABE244E45144C70D11DBBAD
        9D6DE7B969DAE739EDE969897F828E25899D5FA8F31CB8E6D6273418C970CBB5
        5B089348CE4830E6AB4B90FC9AD4F099EF4117974273834E6E1874736DD0C30B
        430B527FF06524D4F881079D6071654CE8E7D2D4F594151CDFC1DB8C151CC10A
        7356F046DAEC05336EDCCFE48F2208EFBC3BF9729E364A38D0DEB839D8670FDD
        67CBC83938D84FCF0FE33F46C1C161B7C7155A65437370D439E40BCA86C1C193
        368E182BA3FF6471F094616128A1C4D36B9EB1A98C032E6D2E1F264A420CB9C8
        168EEF81CD0D4C41EDB197CDEF806DF62BAF72E1D7B0637759086E63126B01AD
        91F558E48521F8E307186B739CA70592460000002574455874646174653A6372
        6561746500323032302D30382D30315431323A32353A34382B30303A30305FE6
        8CC30000002574455874646174653A6D6F6469667900323032302D30382D3031
        5431323A32353A34382B30303A30302EBB347F0000001974455874536F667477
        617265007777772E696E6B73636170652E6F72679BEE3C1A0000000049454E44
        AE426082}
      ShowHint = True
      OnClick = btnAlterarClick
    end
    object btnExcluir: TImage
      Left = 175
      Top = 12
      Width = 39
      Height = 35
      Cursor = crHandPoint
      Hint = 'Excluir Conta selecionada'
      ParentShowHint = False
      Picture.Data = {
        0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
        0020080300000044A48AC60000000467414D410000B18F0BFC61050000019850
        4C544500000000274E002E53022E53012D52012E52012E52012E52002E510033
        52022E53012E52022E52002B55003955022D52012E52022F53002449012E5201
        2F52002C4E002C53012E52012E52002E51002B55012E5200314E002060012E52
        022D51012E52002C50002B55002F53022F52012E52012E52012E52012E52012E
        52022F52022D52002D53002D51002F51A75948012E52002E5DFF7142FF7043FF
        7044002E55FF7744FF7043022E52FF6F41FF7043012E52002B55FF7044012E52
        002E5146404E012E52002F53002D53022E52012E52012D51002F52022D52012E
        52012E521433512E3A504B414D4A414E2337507F4F4ACF6445FF7043CE634616
        335193544AF96E43925449393D4FE76945EA6B443F3E4E56444DF76D4455444D
        3A3D4F383C4EE66A4415335190534A223650032F529C5749D063467F4E4A9B56
        49D16446CD63469D5749022E52955449965549FE7043133351303B4F2F3A4F49
        414E4D414E48404E3B3D4EDB6646052F52DE68458F534AE56A44373C4F54434D
        EB6B44042E52193550FC704324375085504AD765454C414E000000D7C3B32E00
        00004A74524E53000D599ACAEAFAC9581997F59B240982F48807D1C5172EE8E2
        2C18E51A08C787F9230C5699C8EBE9F8F6939850554CABF30B1BF68B210FD985
        27EFC30640E0165FE12B6C86F7F15792E3742ACFB400000001624B4744008805
        1D48000000097048597300000EE900000EE9010E33421C0000000774494D4507
        E408010C1B110351CD9C000001FE4944415478DA7D536B4F1341143D67DD65A1
        150884564A632D94AA542C115F111F34128D7FD9C4689A1043402C26586D91F2
        B20FAD2921A2A4B1BBEBEC763AED4AE3F9B03339F7DCB977CE9D2514E8018ED6
        329A4E97ED6C86C865C566C99F7EC108B9240FB11D37FD55908D1EC1F0C07DC0
        700B789CE5FC01D6595782306F2340B654099DD66FBC67550AA6EC4551A3895E
        0CF2181FF8D5135CE63CC6F90B7E04F903EB76C3158C3E44C8FE372E1417BEE3
        E381100C994B01A389F318652DCF3D229041D0423F8C55F1D22203CB86D9EEDF
        9197EEACFA48E5ED38B51718D0DAFC044463C08403CDB300E1431478F109CC76
        42C82E47F56FB8D42A478D9AC744F650A4FE9CA6AC39D52C27688B8F76D42662
        2CECF0EAECF5FD4E576E32BC6324A63FED329ED275D5B738032A5F60265FE2DC
        F48D5DBFC035586276BBC4E8C2CD9DFF963057983CEC36A959FE26B7998A235D
        943EA86B4A1FC4350F381F5BE067E983324AFA208C3A22D24CC88A21D47DABB0
        BAE23EB2455EE93B2BCCE550FCE2BA7C27D6379ECA39A5E10D57708FD13EF160
        7C138DB5F6601F70F27C7CFA1D4EB82A27FFD87A56F23FBA143771CAACFA7132
        19D6225B2AAC27B71C9CF1359460C5740BB1EE791AB15A15E044CFA22B783448
        432CD7AAE9353B5910BBFCA4BE8A1E0170F778A63BF6CAE9D886DCB2DBD7AD30
        DF3CDD3F33ED7242CF29F62F9AB2AEF4E7064581000000257445587464617465
        3A63726561746500323032302D30382D30315431323A32373A31372B30303A30
        30E5BB22730000002574455874646174653A6D6F6469667900323032302D3038
        2D30315431323A32373A31372B30303A303094E69ACF0000001974455874536F
        667477617265007777772E696E6B73636170652E6F72679BEE3C1A0000000049
        454E44AE426082}
      ShowHint = True
      OnClick = btnExcluirClick
    end
    object Image1: TImage
      Left = 488
      Top = 14
      Width = 36
      Height = 33
      Cursor = crHandPoint
      Hint = 'Fechar a tela'
      ParentShowHint = False
      Picture.Data = {
        0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
        0020080300000044A48AC60000000467414D410000B18F0BFC61050000019250
        4C54450000000000000000000000000000000000000000000000000000000000
        00514F4F000000000000000000000000F2ECEC00000000000000000000000000
        00003D3C3C000000000000000000000000000000000000000000000000000000
        000000000000000000000000000000000000000000000000A19D9D0000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000202024E4C4C605E5E1C1C1C120A
        0B010101141313999595F0EAEAF1EBEB5755555E363BC2707A2B191B3B3939CA
        C5C5FE929FF88F9B834C520805050807077B7878EBE5E5636161DA7D8944272A
        272626B7B3B3D7D1D1A35E66160D0E050505CBC6C6EC8894553135A6A2A2AD64
        6CD5CFCF5F5C5C504E4EABA7A7101010E986922E1A1DEFE9E9AE646DB367707C
        79792F1B1D706D6DA19D9D373535251517CD7680040202724147F38C981F1213
        B1666F4C2C2FE1818D0B0607874E55AA626B140B0CE43ADEC30000004474524E
        530095FDED990C97EAFCEEDC48034114AC7ADE12B201E3AA9C1F07CD73982BFE
        E64BA74FE092FA38C1131B4CD3A5E8FBF6BEE12C19AC89550ADF80F930C90266
        F14DD7D11122448E3800000001624B47440088051D4800000009704859730000
        0EE900000EE9010E33421C0000000774494D4507E4080401120F179A28D70000
        01784944415478DA7DD2694B02411807F0FF5FA9C4CA8CCA4ECD4C848C083A08
        BAE8FAB27E81DE855DBE08BA29952C538AEE0C0BAD34A21D9D755BD7F57931EC
        ECFC66E6796686E40A0C11268BF293961AE34A6C1754B0566A49DD307F76BE35
        D0C0029AF484B9DD2F0DB490EF401B0BA6A04199FE822EF243058E87C8E77F00
        D87807F43323FF768498437969098056A6E1E5A3145B59A5714E1D30530168E7
        15FC777A80236A009D89121810F584284A67103123703CC855E2B76E06124630
        C868A91BE94E71155746A0E5E0F3E1FAAD1EF07BD3BCA0272040DF8D276FD5C0
        F03AE3C048B1310A09DCA718CF6B20707C7FAE3FC92A507D17628BE1ACB50A34
        0F3DC1F55B3BC91218EB16C5D6017EBB0B4FF13A4097431D502E538209F9EEB8
        FF7CA281692654A0C5CBB10A467B3143716E3AF0CA43154CD209CC8A1B544056
        6E110BEE55DE2FE0ED6901E679A6806412D521A6CC5868C722B969068039DA80
        E5B039C002298A3507CAE5372BC95EA6CC01B0A43CE30D03F80308D997DB4DD2
        7E000000002574455874646174653A63726561746500323032302D30382D3034
        5430313A31383A31352B30303A303040515E780000002574455874646174653A
        6D6F6469667900323032302D30382D30345430313A31383A31352B30303A3030
        310CE6C40000001974455874536F667477617265007777772E696E6B73636170
        652E6F72679BEE3C1A0000000049454E44AE426082}
      ShowHint = True
      OnClick = Image1Click
    end
    object labelDescricao: TLabel
      Left = 15
      Top = 74
      Width = 75
      Height = 13
      Caption = 'Nome Fantasia:'
      FocusControl = editNomeFantasia
    end
    object labelCNPJ: TLabel
      Left = 551
      Top = 72
      Width = 25
      Height = 13
      Caption = 'CNPJ'
      FocusControl = editCNPJ
    end
    object labelTelefone: TLabel
      Left = 551
      Top = 119
      Width = 42
      Height = 13
      Caption = 'Telefone'
      FocusControl = editTelefone
    end
    object labelRazaoSocial: TLabel
      Left = 15
      Top = 118
      Width = 64
      Height = 13
      Caption = 'Raz'#227'o Social:'
      FocusControl = editRazaoSocial
    end
    object editNomeFantasia: TDBEdit
      Left = 15
      Top = 87
      Width = 520
      Height = 21
      CharCase = ecUpperCase
      DataField = 'NOME_FANTASIA'
      DataSource = dsFornecedores
      TabOrder = 0
    end
    object editCNPJ: TDBEdit
      Left = 551
      Top = 87
      Width = 238
      Height = 21
      DataField = 'CNPJ'
      DataSource = dsFornecedores
      TabOrder = 1
    end
    object editTelefone: TDBEdit
      Left = 551
      Top = 132
      Width = 238
      Height = 21
      DataField = 'TELEFONE'
      DataSource = dsFornecedores
      TabOrder = 2
    end
    object editRazaoSocial: TDBEdit
      Left = 15
      Top = 132
      Width = 520
      Height = 21
      CharCase = ecUpperCase
      DataField = 'RAZAO_SOCIAL'
      DataSource = dsFornecedores
      TabOrder = 3
    end
    object gbPesquisaFornecedor: TGroupBox
      Left = 15
      Top = 176
      Width = 786
      Height = 80
      Caption = '  Pesquisar Fornecedor  '
      TabOrder = 4
      object editPesquisaFornecedor: TEdit
        Left = 16
        Top = 49
        Width = 758
        Height = 21
        CharCase = ecUpperCase
        TabOrder = 0
        OnChange = editPesquisaFornecedorChange
        OnKeyPress = editPesquisaFornecedorKeyPress
      end
      object RBrazaoSocial: TRadioButton
        Left = 16
        Top = 28
        Width = 153
        Height = 17
        Caption = 'Raz'#227'o Social:'
        TabOrder = 1
        OnClick = RBrazaoSocialClick
      end
      object RBnomeFantasia: TRadioButton
        Left = 186
        Top = 28
        Width = 159
        Height = 17
        Caption = 'Nome Fantasia:'
        TabOrder = 2
        OnClick = RBnomeFantasiaClick
      end
    end
  end
  object gridFornecedores: TDBGrid
    Left = 0
    Top = 265
    Width = 855
    Height = 287
    Align = alClient
    DataSource = dsFornecedores
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnDrawColumnCell = gridFornecedoresDrawColumnCell
    OnDblClick = gridFornecedoresDblClick
    OnKeyPress = gridFornecedoresKeyPress
    Columns = <
      item
        Expanded = False
        FieldName = 'FORNECEDOR_ID'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'NOME_FANTASIA'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'RAZAO_SOCIAL'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CNPJ'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'TELEFONE'
        Visible = True
      end>
  end
  object dsFornecedores: TDataSource
    DataSet = FDqryFornecedores
    Left = 472
    Top = 432
  end
  object FDtcFornecedores: TFDTransaction
    Options.AutoStop = False
    Connection = frmPrincipal.FDconexao
    Left = 352
    Top = 376
  end
  object FDqryFornecedores: TFDQuery
    Connection = frmPrincipal.FDconexao
    Transaction = FDtcFornecedores
    UpdateOptions.AssignedValues = [uvFetchGeneratorsPoint, uvGeneratorName]
    UpdateOptions.GeneratorName = 'GEN_FORNECEDOR_ID'
    UpdateOptions.UpdateTableName = 'FORNECEDOR'
    UpdateOptions.KeyFields = 'FORNECEDOR_ID'
    UpdateOptions.AutoIncFields = 'FORNECEDOR_ID'
    SQL.Strings = (
      'select * from FORNECEDOR order by NOME_FANTASIA')
    Left = 472
    Top = 376
    object FDqryFornecedoresFORNECEDOR_ID: TIntegerField
      DisplayLabel = 'ID'
      FieldName = 'FORNECEDOR_ID'
      Origin = 'FORNECEDOR_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      Required = True
    end
    object FDqryFornecedoresCNPJ: TStringField
      FieldName = 'CNPJ'
      Origin = 'CNPJ'
      Size = 18
    end
    object FDqryFornecedoresTELEFONE: TStringField
      DisplayLabel = 'Telefone:'
      FieldName = 'TELEFONE'
      Origin = 'TELEFONE'
    end
    object FDqryFornecedoresNOME_FANTASIA: TStringField
      DisplayLabel = 'Nome Fantasia:'
      FieldName = 'NOME_FANTASIA'
      Origin = 'NOME_FANTASIA'
      Size = 40
    end
    object FDqryFornecedoresRAZAO_SOCIAL: TStringField
      DisplayLabel = 'Raz'#227'o Social:'
      FieldName = 'RAZAO_SOCIAL'
      Origin = 'RAZAO_SOCIAL'
      Size = 40
    end
  end
end
