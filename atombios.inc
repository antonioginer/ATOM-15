'==============================================================================
'  ATOM-15 v1.0
'  ATOMBIOS 15/25/31 kHz Modder
'
'  Author: Antonio Giner González
'  Date:   October 2014
'
'  atombios.inc
'
'  All constants and structures ported from Linux open source drivers:
'   drivers\gpu\drm\radeon\atombios.h
'==============================================================================

'  Define offset to location of ROM header.

  %OFFSET_TO_POINTER_TO_ATOM_ROM_HEADER    = &h00000048
  %OFFSET_TO_ATOM_ROM_IMAGE_SIZE           = &h00000002

  %OFFSET_TO_ATOMBIOS_ASIC_BUS_MEM_TYPE    = &h94
  %MAXSIZE_OF_ATOMBIOS_ASIC_BUS_MEM_TYPE   = 20    ' including the terminator 0x0!
  %OFFSET_TO_GET_ATOMBIOS_STRINGS_NUMBER   = &h002f
  %OFFSET_TO_GET_ATOMBIOS_STRINGS_START    = &h006e

' Common header for all ROM Data tables.
' Every table pointed  _ATOM_MASTER_DATA_TABLE has this common header.
' And the pointer actually points to this header.

Type ATOM_COMMON_TABLE_HEADER
  usStructureSize As Word
  ucTableFormatRevision As Byte
  ucTableContentRevision As Byte
End Type

' Structure stores the ROM header.
Type ATOM_ROM_HEADER
  sHeader As ATOM_COMMON_TABLE_HEADER
  uaFirmWareSignature As String * 4    ' Signature to distinguish between Atombios and non-atombios, atombios should init it as "ATOM", don't change the position
  usBiosRuntimeSegmentAddress As Word
  usProtectedModeInfoOffset As Word
  usConfigFilenameOffset As Word
  usCRC_BlockOffset As Word
  usBIOS_BootupMessageOffset As Word
  usInt10Offset As Word
  usPciBusDevInitCode As Word
  usIoBaseAddress As Word
  usSubsystemVendorID As Word
  usSubsystemID As Word
  usPCI_InfoOffset As Word
  usMasterCommandTableOffset As Word 'Offset for SW to get all command table offsets, Don't change the position
  usMasterDataTableOffset As Word    'Offset for SW to get all data table offsets, Don't change the position
  ucExtendedFunctionCode As Byte
  ucReserved As Byte
End Type

Type ATOM_MASTER_LIST_OF_DATA_TABLES
  UtilityPipeLine As Word          ' Offest for the utility to get parser info,Don't change this position!
  MultimediaCapabilityInfo As Word ' Only used by MM Lib,latest version 1.1, not configuable from Bios, need to include the table to build Bios
  MultimediaConfigInfo As Word     ' Only used by MM Lib,latest version 2.1, not configuable from Bios, need to include the table to build Bios
  StandardVESA_Timing As Word      ' Only used by Bios
  FirmwareInfo As Word             ' Shared by various SW components,latest version 1.4
  PaletteData As Word              ' Only used by BIOS
  LCD_Info As Word                 ' Shared by various SW components,latest version 1.3, was called LVDS_Info
  DIGTransmitterInfo As Word       ' Internal used by VBIOS only version 3.1
  AnalogTV_Info As Word            ' Shared by various SW components,latest version 1.1
  SupportedDevicesInfo As Word     ' Will be obsolete from R600
  GPIO_I2C_Info As Word            ' Shared by various SW components,latest version 1.2 will be used from R600
  VRAM_UsageByFirmware As Word     ' Shared by various SW components,latest version 1.3 will be used from R600
  GPIO_Pin_LUT As Word             ' Shared by various SW components,latest version 1.1
  VESA_ToInternalModeLUT As Word   ' Only used by Bios
  ComponentVideoInfo As Word       ' Shared by various SW components,latest version 2.1 will be used from R600
  PowerPlayInfo As Word            ' Shared by various SW components,latest version 2.1,new design from R600
  CompassionateData As Word        ' Will be obsolete from R600
  SaveRestoreInfo As Word          ' Only used by Bios
  PPLL_SS_Info As Word             ' Shared by various SW components,latest version 1.2, used to call SS_Info, change to new name because of int ASIC SS info
  OemInfo As Word                  ' Defined and used by external SW, should be obsolete soon
  XTMDS_Info As Word               ' Will be obsolete from R600
  MclkSS_Info As Word              ' Shared by various SW components,latest version 1.1, only enabled when ext SS chip is used
  Object_Header As Word            ' Shared by various SW components,latest version 1.1
  IndirectIOAccess As Word         ' Only used by Bios,this table position can't change at all!!
  MC_InitParameter As Word         ' Only used by command table
  ASIC_VDDC_Info As Word           ' Will be obsolete from R600
  ASIC_InternalSS_Info As Word     ' New tabel name from R600, used to be called "ASIC_MVDDC_Info"
  TV_VideoMode As Word             ' Only used by command table
  VRAM_Info As Word                ' Only used by command table, latest version 1.3
  MemoryTrainingInfo As Word       ' Used for VBIOS and Diag utility for memory training purpose since R600. the new table rev start from 2.1
  IntegratedSystemInfo As Word     ' Shared by various SW components
  ASIC_ProfilingInfo As Word       ' New table name from R600, used to be called "ASIC_VDDCI_Info" for pre-R600
  VoltageObjectInfo As Word        ' Shared by various SW components, latest version 1.1
  PowerSourceInfo As Word          ' Shared by various SW components, latest versoin 1.1
End Type

Type ATOM_MASTER_DATA_TABLE
  sHeader As ATOM_COMMON_TABLE_HEADER
  ListOfDataTables As ATOM_MASTER_LIST_OF_DATA_TABLES
End Type

' usModeMiscInfo-
  %ATOM_H_CUTOFF           = &h01
  %ATOM_HSYNC_POLARITY     = &h02             '0=Active High, 1=Active Low
  %ATOM_VSYNC_POLARITY     = &h04             '0=Active High, 1=Active Low
  %ATOM_V_CUTOFF           = &h08
  %ATOM_H_REPLICATIONBY2   = &h10
  %ATOM_V_REPLICATIONBY2   = &h20
  %ATOM_COMPOSITESYNC      = &h40
  %ATOM_INTERLACE          = &h80
  %ATOM_DOUBLE_CLOCK_MODE  = &h100
  %ATOM_RGB888_MODE        = &h200

' usRefreshRate-
  %ATOM_REFRESH_43         = 43
  %ATOM_REFRESH_47         = 47
  %ATOM_REFRESH_56         = 56
  %ATOM_REFRESH_60         = 60
  %ATOM_REFRESH_65         = 65
  %ATOM_REFRESH_70         = 70
  %ATOM_REFRESH_72         = 72
  %ATOM_REFRESH_75         = 75
  %ATOM_REFRESH_85         = 85

Type ATOM_MODE_MISC_INFO
  HorizontalCutOff As Bit * 1 In Word
  HSyncPolarity As Bit * 1      '0=Active High, 1=Active Low
  VSyncPolarity As Bit * 1      '0=Active High, 1=Active Low
  VerticalCutOff As Bit * 1
  H_ReplicationBy2 As Bit * 1
  V_ReplicationBy2 As Bit * 1
  CompositeSync As Bit * 1
  Interlace As Bit * 1
  DoubleClock As Bit * 1
  RGB888 As Bit * 1
  Reserved As Bit * 6
End Type

Union ATOM_MODE_MISC_INFO_ACCESS
  sbfAccess As ATOM_MODE_MISC_INFO
  usAccess As Word
End Union

Type ATOM_MODE_TIMING
  usCRTC_H_Total As Word
  usCRTC_H_Disp As Word
  usCRTC_H_SyncStart As Word
  usCRTC_H_SyncWidth As Word
  usCRTC_V_Total As Word
  usCRTC_V_Disp As Word
  usCRTC_V_SyncStart As Word
  usCRTC_V_SyncWidth As Word
  usPixelClock As Word        'in 10Khz unit
  susModeMiscInfo As ATOM_MODE_MISC_INFO_ACCESS
  usCRTC_OverscanRight As Word
  usCRTC_OverscanLeft As Word
  usCRTC_OverscanBottom As Word
  usCRTC_OverscanTop As Word
  usReserve As Word
  ucInternalModeNumber As Byte
  ucRefreshRate As Byte
End Type

Type ATOM_DTD_FORMAT
  usPixClk As Word
  usHActive As Word
  usHBlanking_Time As Word
  usVActive As Word
  usVBlanking_Time As Word
  usHSyncOffset As Word
  usHSyncWidth As Word
  usVSyncOffset As Word
  usVSyncWidth As Word
  usImageHSize As Word
  usImageVSize As Word
  ucHBorder As Byte
  ucVBorder As Byte
  susModeMiscInfo As ATOM_MODE_MISC_INFO_ACCESS
  ucInternalModeNumber As Byte
  ucRefreshRate As Byte
End Type

Union ATOM_TIMINGS
  New(48) As ATOM_DTD_FORMAT
  old(48) As ATOM_MODE_TIMING
End Union

Type ATOM_STANDARD_VESA_TIMING
  sHeader As ATOM_COMMON_TABLE_HEADER
  aModeTimings As ATOM_TIMINGS
End Type

Type ATOM_VESA_TO_EXTENDED_MODE
  usVESA_ModeNumber As Word
  usExtendedModeNumber As Word
End Type

Type ATOM_VESA_TO_INTENAL_MODE_LUT
  sHeader As ATOM_COMMON_TABLE_HEADER
  asVESA_ToExtendedModeInfo(76) As ATOM_VESA_TO_EXTENDED_MODE
End Type
