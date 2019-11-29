'==============================================================================
'  ATOM-15 v1.5
'  ATOMBIOS 15/25/31 kHz Modder
'
'  Author: Antonio Giner González
'  Date:   October 2014 - December 2017
'
'  atom-15.bas
'==============================================================================

#Compile Exe
#Dim All
#Resource Manifest, 1, "XPTheme.xml"
#Resource Icon, 1000, "atom.ico"
#Include "atombios.inc"
#Include ".\radeon_family.inc"

'============================================================
'  Constants
'============================================================

  $APP_NAME = "ATOM-15 v1.5"
  %BIOS_MAX_SIZE = 256 * 1024
  %BIOS_MIN_SIZE = 64 * 1024
  %BIOS_ENTRY_POINT = &h0003
  %BIOS_HOOK_OFFSET_MIN = &h0e000
  %BIOS_END_OFFSET = &h0ffff
  %CHECK_SUM_FIX = 256
  %INTERLACE_ENABLE = 1
  %DOT_CLOCK_MIN = 8000000
  %SHOW_INFO = 1
  %REPROGRAM = 2
  %IDC_OPEN = %WM_User + 2001
  %IDC_PATCH = %WM_User + 2002
  %IDC_EXIT = %WM_User + 2003
  %IDC_LOGS = %WM_User + 2004
  %IDC_CHECK_15 = %WM_User + 2005
  %IDC_CHECK_25 = %WM_User + 2006
  %IDC_CHECK_31 = %WM_User + 2007
  %IDC_CHECK_CSYNC = %WM_User + 2008
  %IDC_FRAME1 = %WM_User + 2009
  %IDC_FRAME2 = %WM_User + 2010
  %IDC_LABEL0 = %WM_User + 2100
  %IDC_LABEL1 = %WM_User + 2101
  %IDC_LABEL2 = %WM_User + 2102
  %IDC_LABEL3 = %WM_User + 2103
  %IDC_LABEL4 = %WM_User + 2104
  %IDC_LABEL5 = %WM_User + 2105
  %IDC_LABEL6 = %WM_User + 2106
  %IDC_LABEL7 = %WM_User + 2107
  %IDC_LABEL8 = %WM_User + 2108
  %IDC_LABEL9 = %WM_User + 2109

  %VENDOR_ATI = &h1002

  %SCAN_TYPE_0    = 0
  %SCAN_TYPE_1    = 1
  %SCAN_TYPE_2    = 2
  %SCAN_TYPE_3    = 3
  %SCAN_INTERLACE = &h080
  %SCAN_TEXT      = &h100

  %CLOCK_DIV_2 = &h080
  %CLOCK_25175 = 0
  %CLOCK_28322 = 1
  %CLOCK_65000 = 2
  %CLOCK_12587 = %CLOCK_25175 Or %CLOCK_DIV_2
  %CLOCK_14161 = %CLOCK_28322 Or %CLOCK_DIV_2
  %CLOCK_32500 = %CLOCK_65000 Or %CLOCK_DIV_2

'============================================================
'  Types
'============================================================

' These tables are ported from Paul Borman's site:
' http:'www.kryslix.com/nsfaq/Q.7.html
' --------------
' Format of Video Parameter Table [EGA, VGA only]:
' Elements appear in the order:
'  00h-03h        Modes 00h-03h In 200-Line CGA emulation Mode
'  04h-0Eh        Modes 04h-0Eh
'  0Fh-10h        Modes 0Fh-10h when Only 64kB RAM On adapter
'  11h-12h        Modes 0Fh-10h when >64kB RAM On adapter
'  13h-16h        Modes 00h-03h In 350-Line Mode
'  17h            VGA Modes 00h Or 01h In 400-Line Mode
'  18h            VGA Modes 02h Or 03h In 400-Line Mode
'  19h            VGA Mode  07h In 400-Line Mode
'  1Ah-1Ch        VGA Modes 11h-13h
' --------
' Format of Video Parameter Table element [EGA, VGA only]:
Type VBIOS_MODE
  columns           As Byte 'Columns on screen                 (see 40h:4Ah)
  rows              As Byte 'Rows on screen minus one          (see 40h:84h)
  char_height       As Byte 'Height of character in scan lines (see 40h:85h)
  video_buffer_size As Word 'Size of video buffer              (see 40h:4Ch)
  sequencer(3)      As Byte 'Values for Sequencer Registers 1-4
  miscellaneous     As Byte 'Value for Miscellaneous Output Register
  crtc(24)          As Byte 'Values for CRTC Registers 00h-18h
  attribute(19)     As Byte 'Values for Attribute Controller Registers 00h-13h
  graphics(8)       As Byte 'Values for Graphics Controller Registers 00h-08h
End Type

Type VIDEO_PARAMETER_TABLE
  vm(28) As VBIOS_MODE
End Type

' Types specific of this program
Type VIDEO_MODE_DEF
  bios_num                  As Long
  offset                    As Long
  width                     As Long
  height                     As Long
  num_colors                As Long
  graphic_mode              As Long
  buffer_size               As Long
  horizontal_total          As Long
  horizontal_display_end    As Long
  horizontal_blanking_start As Long
  horizontal_blanking_end   As Long
  horizontal_retrace_start  As Long
  horizontal_retrace_end    As Long
  vertical_display_end      As Long
  vertical_retrace_start    As Long
  vertical_retrace_end      As Long
  vertical_total            As Long
  vertical_blanking_start   As Long
  vertical_blanking_end     As Long
  cursor_start              As Long
  cursor_end                As Long
  horizontal_retrace_skew   As Long
  display_enable_skew       As Long
  dots_per_char             As Long
  lines_per_char            As Long
  line_pitch                As Long
  clock_select              As Long
  dotclock_div              As Long
  maximum_scan_line         As Long
  scan_doubling             As Long
  interlace                 As Long
  line_compare              As Long
  hsync_polarity            As Long
  vsync_polarity            As Long
  hfreq                     As Double
  vfreq                     As Double
  dotclock                  As Double
  mode_label                As String * 128
End Type

Type MODELINE
  pclock As Long
  hactive As Long
  hbegin As Long
  hend As Long
  htotal As Long
  vactive As Long
  vbegin As Long
  vend As Long
  vtotal As Long
  interlace As Long
  doublescan As Long
  hsync As Long
  vsync As Long
  vfreq As Double
  hfreq As Double
  width As Long
  height As Long
  refresh As Long
  number As Long
End Type

Type MONITOR_RANGE
  h_freq_min                As Double
  h_freq_max                As Double
  v_freq_min                As Double
  v_freq_max                As Double
  h_front_porch             As Double
  h_sync_pulse              As Double
  h_back_porch              As Double
  v_front_porch             As Double
  v_sync_pulse              As Double
  v_back_porch              As Double
  h_sync_polarity           As Long
  v_sync_polarity           As Long
  vertical_blank            As Double
End Type

Type BIOS_MODES
  standard(19)              As Byte
  vesa(255)                 As Byte
End Type

Type ATOMBIOS
  bios_ptr                  As String Ptr * %BIOS_MAX_SIZE
  file_name                 As String Ptr
  file_length               As Long
  rom_header_ptr            As ATOM_ROM_HEADER Ptr
  master_data_table_ptr     As ATOM_MASTER_DATA_TABLE Ptr
  standard_vesa_timing_ptr  As ATOM_STANDARD_VESA_TIMING Ptr
  vesa_to_internal_mode_ptr As ATOM_VESA_TO_INTENAL_MODE_LUT Ptr
  video_parameter_table_ptr As VIDEO_PARAMETER_TABLE Ptr
  int_10h_proc              As Word
  standard_service_call_off As Word
  standard_service_proc     As Word
  vesa_service_call_off     As Word
  vesa_service_proc         As Word
  pci_bus_off               As Word
  pci_vendor                As Word
  pci_device                As Dword
  family                    As Dword
  checksum                  As Word
  num_of_standard_modes     As Long
  num_of_vesa_modes         As Long
  num_of_vesa_timings       As Long
  modes_old_format          As Long
  vesa_old_format           As Long
  log_file_handle           As Long
  reprogram_table           As BIOS_MODES
  mcuc_offset_ptr           As Long Ptr
  mcuc_block_ptr            As Long Ptr
  gop_ptr                   As Long
End Type

Macro exit_error(message) = error_message = message : Exit Function

'============================================================
'  PBMain
'============================================================

Function PBMain () As Long

  Global bios, bios_mod As String * %BIOS_MAX_SIZE
  Global bios_info, bios_mod_info As ATOMBIOS
  Global bios_file, bios_mod_file As String

  Dim crt_range(2) As Global monitor_range
  Global range_15, range_25, range_31 As Long
  Global composite_sync As Long

  Dim clock(4) As Global Double
  clock(0) = 25.175
  clock(1) = 28.322
  clock(2) = 65.000

  Global error_message As String
  error_message = "Unknown error."

  Local hDlg, hFont, i As Long
  Dialog New %HWND_Desktop, $APP_NAME,,, 256, 126, %WS_Caption Or %WS_MinimizeBox Or %WS_SysMenu, 0 To hDlg
  Dialog Set Icon hDlg, "#1000"
  Control Add Button, hDlg, %IDC_OPEN, "&Load BIOS...", 124, 48 + 10, 64, 24, %WS_TabStop
  Control Add Button, hDlg, %IDC_PATCH, "&Patch BIOS",  190, 48 + 10, 64, 24, %WS_TabStop Or %WS_Disabled
  Control Add Button, hDlg, %IDC_LOGS, "&View log", 124, 76 + 10, 64, 24, %WS_TabStop Or %WS_Disabled
  Control Add Button, hDlg, %IDC_EXIT, "&Exit", 190, 76 + 10, 64, 24, %WS_TabStop
  Control Add CheckBox, hDlg, %IDC_CHECK_15, "15 kHz", 127, 30, 36, 8, %WS_TabStop
  Control Add CheckBox, hDlg, %IDC_CHECK_25, "25 kHz", 167, 30, 36, 8, %WS_TabStop
  Control Add CheckBox, hDlg, %IDC_CHECK_31, "31 kHz", 207, 30, 36, 8, %WS_TabStop
  Control Add CheckBox, hDlg, %IDC_CHECK_CSYNC, "Enable composite sync", 127, 46, 100, 8, %WS_TabStop
  Control Set Check hDlg, %IDC_CHECK_15, 1
  Control Add Frame, hDlg, %IDC_FRAME1, "Bios information", 2, 16, 120, 94
  Control Add Frame, hDlg, %IDC_FRAME2, "Set monitor operational ranges", 124, 16, 129, 27
  Control Add Label, hDlg, %IDC_LABEL0, "   Bios name: ...", 2, 2, 251, 12, %SS_CenterImage Or %SS_NoWordWrap
  Control Set Color hDlg, %IDC_LABEL0 + i, %rgb_DarkGreen, %rgb_LightGray
  Font New "terminal", 9, 0, 0, 1, 0 To hFont
  For i = 0 To 7
    Control Add Label, hDlg, %IDC_LABEL1 + i, "", 6, 26 + i * 10, 112, 10, %SS_Sunken Or %SS_NoWordWrap
    Control Set Font hDlg, %IDC_LABEL1 + i, hFont
    Control Set Color hDlg, %IDC_LABEL1 + i, %rgb_Blue, %rgb_LightGray
  Next
  Control Add Label, hDlg, %IDC_LABEL9, "Warning: This software is experimental. Use at your own risk", 4, 114, 248, 10
  Control Set Color hDlg, %IDC_LABEL9, %rgb_Red, -2&
  Dialog Show Modal hDlg, Call DlgProc

End Function

'============================================================
'  DlgProc
'============================================================

CallBack Function DlgProc() As Long

  Select Case Cb.Msg
    Case %WM_Command
      If Cb.CtlMsg <> %BN_Clicked Then Exit Select

      Select Case Cb.Ctl
        Case %IDC_OPEN
          If IsFalse(open_bios(Cb.Hndl)) Then finish_with_error
          Function = 1

        Case %IDC_PATCH
          If IsFalse(process_bios(Cb.Hndl)) Then finish_with_error
          Function = 1

        Case %IDC_LOGS
          Local pid1, pid2 As Long
          pid1 = Shell("notepad.exe " + bios_file + ".txt", 1)
          pid2 = Shell("notepad.exe " + bios_mod_file + ".txt", 1)
          Function = 1

        Case %IDC_EXIT, %IdCancel
          Dialog End Cb.Hndl
      End Select
  End Select

  Exit Function

  finish_with_error:
  MsgBox error_message, %MB_TaskModal Or %MB_IconError, "Error"

End Function

'============================================================
'  open_bios
'============================================================

Function open_bios(hDlg As Long) As Long

  Local a As Long

  Control Disable hDlg, %IDC_OPEN
  Control Disable hDlg, %IDC_PATCH
  Control Disable hDlg, %IDC_LOGS

  Display Openfile , , , "Open BIOS file", "", Chr$("BIOS files (*.rom; *.bin)", 0, "*.rom;*.bin", 0), "", "", %OFN_EnableSizing Or %OFN_FileMustExist To bios_file
  Control Enable hDlg, %IDC_OPEN
  If bios_file = "" Then Function = 1 : Exit Function

  Reset bios_info
  Reset bios_mod_info

  bios_info.bios_ptr = VarPtr(bios)
  bios_info.file_name = VarPtr(bios_file)

  a = FreeFile
  Open bios_info.@file_name For Binary As a Base = 0
  If Err Then exit_error("Error opening " + bios_info.@file_name + $CrLf + Error$)
  bios_info.file_length = Min(%BIOS_MAX_SIZE, Lof(a))
  Get$ a, bios_info.file_length, bios
  Close a

  bios_mod = bios
  bios_mod_info.bios_ptr = VarPtr(bios_mod)
  bios_mod_file = PathName$(Path, bios_file) + PathName$(Name, bios_file) + "-mod" + PathName$(Extn, bios_file)
  bios_mod_info.file_name = VarPtr(bios_mod_file)
  bios_mod_info.file_length = bios_info.file_length

  If atombios_get_info(bios_info) And atombios_get_info(bios_mod_info) Then
    Control Enable hDlg, %IDC_PATCH
    Function = 1
  End If

  Control Set Text hDlg, %IDC_LABEL0, Using$("   Bios name: &", PathName$(Namex, bios_info.@file_name))
  Control Set Text hDlg, %IDC_LABEL1, Using$("File size: # bytes", bios_info.file_length)
  Control Set Text hDlg, %IDC_LABEL2, Using$("Vendor ID:        &h", Hex$(bios_info.pci_vendor, 4))
  Control Set Text hDlg, %IDC_LABEL3, Using$("Device ID:        &h", Hex$(bios_info.pci_device, 4))
  Control Set Text hDlg, %IDC_LABEL4, Using$("Checksum:         &h", Hex$(bios_info.checksum, 4))
  Control Set Text hDlg, %IDC_LABEL5, Using$("Int 10h proc:     &h", Hex$(bios_info.int_10h_proc, 4))
  Control Set Text hDlg, %IDC_LABEL6, Using$("Standard service: &h", Hex$(bios_info.standard_service_proc, 4))
  Control Set Text hDlg, %IDC_LABEL7, Using$("VESA service:     &h", Hex$(bios_info.vesa_service_proc, 4))
  Control Set Text hDlg, %IDC_LABEL8, Using$("Legacy BIOS end: &h", Hex$(Peek(Byte, bios_info.bios_ptr + 2) * 512, 5))

End Function


'============================================================
'  process_bios
'============================================================

Function process_bios(hDlg As Long) As Long

  Local a, b As Long
  Local use_range_15, use_range_25, use_range_31 As Long

  range_15 = 0 : range_25 = 0 : range_31 = 0
  Control Get Check hDlg, %IDC_CHECK_15 To use_range_15
  Control Get Check hDlg, %IDC_CHECK_25 To use_range_25
  Control Get Check hDlg, %IDC_CHECK_31 To use_range_31
  If use_range_15 Then range_15 = set_monitor_range(crt_range(0), "15625, 16200, 49.50, 60.00, 2.000, 4.700, 8.000, 0.064, 0.192, 1.024, 0, 0")
  If use_range_25 Then range_25 = set_monitor_range(crt_range(1), "24960, 24960, 49.50, 60.00, 0.800, 4.000, 3.200, 0.080, 0.200, 1.000, 0, 0")
  If use_range_31 Then range_31 = set_monitor_range(crt_range(2), "31400, 31500, 48.50, 60.00, 0.940, 3.770, 1.890, 0.032, 0.064, 0.763, 0, 0")
  If IsFalse(use_range_15 Or use_range_25 Or use_range_31) Then exit_error("At least one frequency range must be selected.")
  Control Get Check hDlg, %IDC_CHECK_CSYNC To composite_sync

  ' open log files
  Close
  a = FreeFile
  Open bios_file + ".txt" For Output As a
  bios_info.log_file_handle = a
  b = FreeFile
  Open bios_mod_file + ".txt" For Output As b
  bios_mod_info.log_file_handle = b

  atombios_show_info(bios_info)
  atombios_show_info(bios_mod_info)

  process_vesa_modes(bios_info, %SHOW_INFO)
  process_vesa_modes(bios_mod_info, %SHOW_INFO Or %REPROGRAM)

  process_standard_modes(bios_info, %SHOW_INFO)
  process_standard_modes(bios_mod_info, %SHOW_INFO Or %REPROGRAM)

  Close

  Local checksum_fix_ptr As Long
  checksum_fix_ptr = bios_hook(bios_mod_info)
  If IsFalse checksum_fix_ptr Then Exit Function
  fix_checksum(bios_mod_info, checksum_fix_ptr)

  a = FreeFile
  Open bios_mod_info.@file_name For Binary As a Base = 0
  If Err Then exit_error("Error opening " + bios_mod_info.@file_name + $CrLf + Error$)
  Put$ #a, Left$(bios_mod, bios_mod_info.file_length)
  Close

  Control Disable hDlg, %IDC_PATCH
  Control Enable hDlg, %IDC_LOGS
  MsgBox PathName$(Namex, bios_info.@file_name) + " patched successfully as " + PathName$(Namex, bios_mod_info.@file_name), %MB_TaskModal Or %MB_IconInformation, $APP_NAME

  Function = 1
End Function

'============================================================
'  atombios_get_info
'============================================================

Function atombios_get_info(b As ATOMBIOS) As Long

  Local vesa_check As Word
  Local bios_init_ptr As String Ptr * 256
  Local bios_init_routine As String * 256
  Local pci_bus_get_offset As Long
  Local bios_end_offset As Long

  b.rom_header_ptr = b.bios_ptr + Peek(Word, b.bios_ptr + %OFFSET_TO_POINTER_TO_ATOM_ROM_HEADER)
  If b.@rom_header_ptr.uaFirmWareSignature <> "ATOM" Then exit_error("ATOM signature not found.")

  b.pci_vendor = Peek(Word, b.@rom_header_ptr.usPCI_InfoOffset + b.bios_ptr + 4)
  b.pci_device = Peek(Word, b.@rom_header_ptr.usPCI_InfoOffset + b.bios_ptr + 6)

  b.master_data_table_ptr = b.bios_ptr + b.@rom_header_ptr.usMasterDataTableOffset
  b.standard_vesa_timing_ptr = b.bios_ptr + b.@master_data_table_ptr.ListOfDataTables.StandardVESA_Timing
  b.vesa_to_internal_mode_ptr = b.bios_ptr + b.@master_data_table_ptr.ListOfDataTables.VESA_ToInternalModeLUT
  b.int_10h_proc = b.@rom_header_ptr.usInt10Offset
  b.checksum = compute_checksum(b)

  b.video_parameter_table_ptr = InStr(b.@bios_ptr, Chr$(&h28) + Chr$(&h18) + Chr$(&h08) + Chr$(&h00))
  If b.video_parameter_table_ptr = 0 Then exit_error("Video parameter table not found.")
  b.video_parameter_table_ptr += b.bios_ptr - 1

  If b.@video_parameter_table_ptr.vm(1).columns = 80 Then
    b.modes_old_format = 1
    b.num_of_standard_modes = 20
  Else
    b.num_of_standard_modes = SizeOf(VIDEO_PARAMETER_TABLE) / SizeOf(VBIOS_MODE)
  End If

  b.num_of_vesa_modes = (b.@vesa_to_internal_mode_ptr.sHeader.usStructureSize - SizeOf(ATOM_COMMON_TABLE_HEADER)) / SizeOf(ATOM_VESA_TO_EXTENDED_MODE)
  b.vesa_old_format = IIf((b.@standard_vesa_timing_ptr.sHeader.usStructureSize - SizeOf(ATOM_COMMON_TABLE_HEADER)) Mod SizeOf(ATOM_DTD_FORMAT), 1, 0)
  b.num_of_vesa_timings = (b.@standard_vesa_timing_ptr.sHeader.usStructureSize - SizeOf(ATOM_COMMON_TABLE_HEADER)) / IIf(b.vesa_old_format, SizeOf(ATOM_MODE_TIMING), SizeOf(ATOM_DTD_FORMAT))

  vesa_check = InStr(b.int_10h_proc, b.@bios_ptr, Chr$(&h80) + Chr$(&h0fc) + Chr$(&h4f))
  If vesa_check = 0 Then exit_error("Vesa check point not found.")
  Decr vesa_check

  b.standard_service_call_off = vesa_check + 10
  If Peek(Byte, b.standard_service_call_off + b.bios_ptr) = &he8 Then
    b.standard_service_proc = Peek(Word, b.standard_service_call_off + 1 + b.bios_ptr) + b.standard_service_call_off + 3
  Else
    exit_error("Standard video service proc not found.")
  End If

  b.vesa_service_call_off = vesa_check + 5
  If Peek(Byte, b.vesa_service_call_off + b.bios_ptr) = &he8 Then
    b.vesa_service_proc = Peek(Word, b.vesa_service_call_off + 1 + b.bios_ptr) + b.vesa_service_call_off + 3
  Else
    exit_error("Vesa video service proc not found.")
  End If

  bios_init_ptr = Peek(Word, b.bios_ptr + %BIOS_ENTRY_POINT + 1) + %BIOS_ENTRY_POINT + 3 + b.bios_ptr
  bios_init_routine = @bios_init_ptr
  pci_bus_get_offset = InStr(bios_init_routine, Chr$(&hA3))
  If pci_bus_get_offset = 0 Then exit_error("PCI Bus offset not found.")
  Decr pci_bus_get_offset
  b.pci_bus_off = Peek(Word, bios_init_ptr + pci_bus_get_offset + 1)

  b.mcuc_offset_ptr = InStr(b.@bios_ptr, "MCuC")
  If b.mcuc_offset_ptr <> 0 Then
    b.mcuc_offset_ptr += b.bios_ptr - 9
    b.mcuc_block_ptr = b.@mcuc_offset_ptr + b.bios_ptr
  End If

  bios_end_offset = Peek(b.bios_ptr + 2) * 512
  If Mid$(b.@bios_ptr, bios_end_offset + 28 + 1, 4) = "PCIR" Then b.gop_ptr = bios_end_offset + b.bios_ptr

  Function = 1
End Function

'============================================================
'  atombios_show_info
'============================================================

Function atombios_show_info(b As ATOMBIOS) As Long

  Local f As Long
  f = b.log_file_handle

  Print #f, title0(" BIOS file = " + b.@file_name)
  Print #f, Using$(" Int 10h proc                = &h", Hex$(b.int_10h_proc, 4))
  Print #f, Using$(" Standard video service proc = &h", Hex$(b.standard_service_proc, 4))
  Print #f, Using$(" Vesa video service proc     = &h", Hex$(b.vesa_service_proc, 4))
  Print #f, Using$(" PCI bus offset              = &h", Hex$(b.pci_bus_off, 4))
  Print #f, Using$(" Video parameter table       = &h", Hex$(b.video_parameter_table_ptr - b.bios_ptr, 4))
  Print #f, Using$(" Vesa to internal mode LUT   = &h", Hex$(b.vesa_to_internal_mode_ptr - b.bios_ptr, 4))
  Print #f, Using$(" Vesa timings table          = &h", Hex$(b.@master_data_table_ptr.ListOfDataTables.StandardVESA_Timing, 4))

  Function = 1
End Function

'============================================================
'  process_standard_modes
'============================================================

Function process_standard_modes(b As ATOMBIOS, action As Long) As Long

  Local i As Long
  Local mode_number As Long
  Local vpt As VIDEO_PARAMETER_TABLE Ptr
  Local vbm As VBIOS_MODE Ptr
  Local vmd As VIDEO_MODE_DEF

  vpt = b.video_parameter_table_ptr

  For i = 0 To b.num_of_standard_modes - 1
    vbm = VarPtr(@vpt.vm(i))
    If @vbm.columns = 0 Then Iterate For

    Reset vmd
    vmd.bios_num = standard_mode_get_bios_num(b, i, vmd.mode_label)
    vmd.offset = vbm - b.bios_ptr

    standard_mode_to_modedef(vbm, vmd)
    If (action And %REPROGRAM) Then standard_mode_reprogram(vbm, vmd)
    If (action And %SHOW_INFO) Then standard_mode_show_info(vbm, vmd, b.log_file_handle)

    b.reprogram_table.standard(vmd.bios_num) = IIf(vmd.interlace, %INTERLACE_ENABLE, 0)
  Next

  Function = 1
End Function

'============================================================
'  standard_mode_get_bios_num
'============================================================

Function standard_mode_get_bios_num(b As ATOMBIOS, i As Long, mode_label As String * 128) As Long

  Local table_select As Long

  If IsFalse b.modes_old_format Then table_select = 20

  mode_label = Read$((i + table_select) * 2 + 2)
  Function = Val("&h" + Right$(Read$((i + table_select) * 2 + 1), 2))

  'Old table format
  Data " 00", "CGA Emulation - 200-lines doublescan"   :'T   40x25  8x8    320x200  16
  Data " 03", "CGA Emulation - 200-lines doublescan"   :'T   80x25  8x8    640x200  16
  Data " 04", "CGA Emulation - 200-lines doublescan"   :'G   40x25  8x8    320x200  4
  Data " 06", "CGA Emulation - 200-lines doublescan"   :'G   80x25  8x8    640x200  2
  Data " 07", "EGA Emulation - 350 lines"              :'T   80x25  9x14   720x350  mono
  Data " 08", "VGA (mode 12h copy?)"                   :'G   80x30  8x16   640x480  16
  Data " 0D", "EGA/VGA"                                :'G   40x25  8x8    320x200  16
  Data " 0E", "EGA/VGA"                                :'G   80x25  8x8    640x200  16
  Data " FF", "reserved"                               :'reserved
  Data " FF", "reserved"                               :'reserved
  Data " 0F", "EGA > 64kB RAM"                         :'G   80x25  8x14   640x350  mono
  Data " 10", "EGA > 64kB RAM"                         :'G   80x25  8x14   640x350  16
  Data " 00", "EGA Emulation - 350-lines"              :'T   40x25  8x14   320x350  16
  Data " 03", "EGA Emulation - 350-lines"              :'T   80x25  8x14   640x350  16
  Data "*00", "VGA - 400 lines"                        :'T   40x25  9x16   360x400  16
  Data "*03", "VGA - 400 lines"                        :'T   80x25  9x16   720x400  16
  Data "*07", "VGA - 400 lines"                        :'T   80x25  9x16   720x400  mono
  Data "*11", "VGA"                                    :'G   80x30  8x16   640x480  mono
  Data "*12", "VGA"                                    :'G   80x30  8x16   640x480  16
  Data "*13", "VGA"                                    :'G   40x25  8x8    320x200  256

  'New table format
  Data " 00", "CGA Emulation - 200-lines doublescan"   :'T   40x25  8x8    320x200  16
  Data " 01", "CGA Emulation - 200-lines doublescan"   :'T   40x25  8x8    320x200  16
  Data " 02", "CGA Emulation - 200-lines doublescan"   :'T   80x25  8x8    640x200  16
  Data " 03", "CGA Emulation - 200-lines doublescan"   :'T   80x25  8x8    640x200  16
  Data "*04", "CGA Emulation - 200-lines doublescan"   :'G   40x25  8x8    320x200  4
  Data "*05", "CGA Emulation - 200-lines doublescan"   :'G   40x25  8x8    320x200  4
  Data "*06", "CGA Emulation - 200-lines doublescan"   :'G   80x25  8x8    640x200  2
  Data " 07", "EGA Emulation - 350 lines"              :'T   80x25  9x14   720x350  mono
  Data " 08", "VGA (mode 12h copy?)"                   :'G   80x30  8x16   640x480  16
  Data " 09", "ATI SVGA"                               :'T  132x25  8x16  1056x400  16
  Data " 0A", "ATI SVGA"                               :'T  132x43  8x8   1056x344  16
  Data " 0B", "ATI SVGA"                               :'T  132x44  8x8   1056x352  16
  Data " 0C", "reserved"                               :'reserved
  Data " 0D", "EGA/VGA"                                :'G   40x25  8x8    320x200  16
  Data " 0E", "EGA/VGA"                                :'G   80x25  8x8    640x200  16
  Data " 0F", "EGA 64kB RAM"                           :'G   80x25  8x14   640x350  mono
  Data " 10", "EGA 64kB RAM"                           :'G   80x25  8x14   640x350  4
  Data " 0F", "EGA > 64kB RAM"                         :'G   80x25  8x14   640x350  mono
  Data " 10", "EGA > 64kB RAM"                         :'G   80x25  8x14   640x350  16
  Data " 00", "EGA Emulation - 350-lines"              :'T   40x25  8x14   320x350  16
  Data " 01", "EGA Emulation - 350-lines"              :'T   40x25  8x14   320x350  16
  Data " 02", "EGA Emulation - 350-lines"              :'T   80x25  8x14   640x350  16
  Data " 03", "EGA Emulation - 350-lines"              :'T   80x25  8x14   640x350  16
  Data "*00", "VGA - 400 lines"                        :'T   40x25  9x16   360x400  16
  Data "*03", "VGA - 400 lines"                        :'T   80x25  9x16   720x400  16
  Data "*07", "VGA - 400 lines"                        :'T   80x25  9x16   720x400  mono
  Data "*11", "VGA"                                    :'G   80x30  8x16   640x480  mono
  Data "*12", "VGA"                                    :'G   80x30  8x16   640x480  16
  Data "*13", "VGA"                                    :'G   40x25  8x8    320x200  256

End Function

'============================================================
'  standard_mode_to_modedef
'============================================================

Function standard_mode_to_modedef(ByVal vbm As VBIOS_MODE Ptr, m As VIDEO_MODE_DEF) As Long

  m.horizontal_total          = @vbm.crtc(&h00) + 5
  m.horizontal_display_end    = @vbm.crtc(&h01)
  m.horizontal_blanking_start = @vbm.crtc(&h02)
  m.horizontal_blanking_end   = match_counter(m.horizontal_blanking_start, (@vbm.crtc(&h03) And &b11111) + (@vbm.crtc(&h05) And &b10000000) / 4, m.horizontal_total, &b111111)
  m.horizontal_retrace_start  = @vbm.crtc(&h04)
  m.horizontal_retrace_end    = match_counter(m.horizontal_retrace_start, (@vbm.crtc(&h05) And &b11111), m.horizontal_total, &b11111)

  m.vertical_display_end    = @vbm.crtc(&h12) + (@vbm.crtc(&h07) And &b10) * 128 + (@vbm.crtc(&h07) And &b1000000) * 8
  m.vertical_total          = @vbm.crtc(&h06) + (@vbm.crtc(&h07) And &b1) * 256 + (@vbm.crtc(&h07) And &b100000) * 16
  m.vertical_retrace_start  = @vbm.crtc(&h10) + (@vbm.crtc(&h07) And &b100) * 64 + (@vbm.crtc(&h07) And &b10000000) * 4
  m.vertical_retrace_end    = match_counter(m.vertical_retrace_start, (@vbm.crtc(&h11)), m.vertical_total, &b1111)
  m.vertical_blanking_start = @vbm.crtc(&h15) + (@vbm.crtc(&h07) And &b1000) * 32 + (@vbm.crtc(&h09) And &b100000) * 16
  m.vertical_blanking_end   = match_counter(m.vertical_blanking_start, (@vbm.crtc(&h16)), m.vertical_total, &b1111111)

  m.maximum_scan_line       = (@vbm.crtc(&h09) And &b11111)
  m.scan_doubling           = Bit(@vbm.crtc(&h09), 7)
  m.line_compare            = @vbm.crtc(&h18) + (@vbm.crtc(&h07) And &b10000) * 16 + (@vbm.crtc(&h09) And &b1000000) * 8
  m.line_pitch              = @vbm.crtc(&h13)

  m.dots_per_char = IIf((@vbm.sequencer(0) And &b1), 8, 9)
  m.lines_per_char = @vbm.char_height
  m.clock_select = (@vbm.miscellaneous And &b1100) / 4
  m.dotclock = clock(m.clock_select)
  m.dotclock_div = Bit(@vbm.sequencer(0),3)
  m.hfreq = (m.dotclock / IIf(m.dotclock_div, 2, 1)) * 1000000 / (m.horizontal_total * m.dots_per_char)
  m.vfreq = m.hfreq / (m.vertical_total / IIf(m.interlace, 2, 1))

  m.width = @vbm.columns * m.dots_per_char
  m.height = (@vbm.rows + 1) * m.lines_per_char
  m.graphic_mode =  Bit(@vbm.attribute(&h10), 0)
  m.buffer_size = @vbm.video_buffer_size

  m.vsync_polarity = IIf(Bit(@vbm.miscellaneous, 7), 0, 1)
  m.hsync_polarity = IIf(Bit(@vbm.miscellaneous, 6), 0, 1)

  If  Bit(@vbm.attribute(&h10), 6) Then
    m.num_colors = 256
  Else
    m.num_colors = 1
    While @vbm.attribute(m.num_colors) > @vbm.attribute(m.num_colors - 1)
      Incr m.num_colors
    Wend
    If m.num_colors > 4 Then m.num_colors = 16
  End If

  Function = 1
End Function

'============================================================
'  standard_mode_from_modedef
'============================================================

Function standard_mode_from_modedef(ByVal vbm As VBIOS_MODE Ptr, m As VIDEO_MODE_DEF) As Long

  @vbm.char_height = m.lines_per_char
  @vbm.video_buffer_size = m.buffer_size

  @vbm.sequencer(0) = set_bit_in_byte(@vbm.sequencer(0), 0, IIf(m.dots_per_char = 8, 1, 0))
  @vbm.sequencer(0) = set_bit_in_byte(@vbm.sequencer(0), 3, m.dotclock_div)

  @vbm.miscellaneous = (@vbm.miscellaneous And &b11110011) Or (m.clock_select * 4)
  @vbm.miscellaneous = set_bit_in_byte(@vbm.miscellaneous, 7, IIf(m.vsync_polarity, 0, 1))
  @vbm.miscellaneous = set_bit_in_byte(@vbm.miscellaneous, 6, IIf(m.hsync_polarity, 0, 1))

  @vbm.crtc(&h00) = m.horizontal_total - 5
  @vbm.crtc(&h01) = m.horizontal_display_end
  @vbm.crtc(&h02) = m.horizontal_blanking_start
  @vbm.crtc(&h03) = (m.horizontal_blanking_end And &b11111) +_
                    (m.display_enable_skew And &b11) * 32 +_
                    &b10000000
  @vbm.crtc(&h04) = m.horizontal_retrace_start
  @vbm.crtc(&h05) = (m.horizontal_retrace_end And &b11111) +_
                    (m.horizontal_retrace_skew And &b11) * 32 +_
                    (m.horizontal_blanking_end And &b100000) * 4
  @vbm.crtc(&h06) = (m.vertical_total And &b11111111)
  @vbm.crtc(&h07) = (m.vertical_total And &b100000000) / 256 + _
                    ((m.vertical_display_end - 1) And &b100000000) / 128 +_
                    (m.vertical_retrace_start And &b100000000) / 64 +_
                    (m.vertical_blanking_start And &b100000000) / 32 +_
                    (m.line_compare And &b100000000) / 16 +_
                    (m.vertical_total And &b1000000000) / 16 +_
                    ((m.vertical_display_end - 1) And &b1000000000) / 8 +_
                    (m.vertical_retrace_start And &b1000000000) / 4
  @vbm.crtc(&h09) = m.maximum_scan_line + _
                    (m.vertical_blanking_start And &b1000000000) / 16 +_
                    (m.line_compare And &b1000000000) / 8 +_
                    m.scan_doubling * 128
  @vbm.crtc(&h0a) = m.cursor_start
  @vbm.crtc(&h0b) = m.cursor_end
  @vbm.crtc(&h10) = (m.vertical_retrace_start And &b11111111)
  @vbm.crtc(&h11) = (m.vertical_retrace_end And &b1111) + (@vbm.crtc(&h11) And &b11110000)
  @vbm.crtc(&h12) = ((m.vertical_display_end - 1) And &b11111111)
  @vbm.crtc(&h13) = m.line_pitch
  @vbm.crtc(&h15) = (m.vertical_blanking_start And &b11111111)
  @vbm.crtc(&h16) = (m.vertical_blanking_end And &b01111111) + (@vbm.crtc(&h16) And &b10000000)
  @vbm.crtc(&h18) = (m.line_compare And &b11111111)

End Function

'============================================================
'  standard_mode_show_info
'============================================================

Function standard_mode_show_info(ByVal vbm As VBIOS_MODE Ptr, m As VIDEO_MODE_DEF, f As Long) As Long

  Local mode_lab As String
  mode_lab =Using$(" Mode: &h", Hex$(m.bios_num, 2)) + Space$(6) + m.mode_label + $CrLf +_
            Using$("       & = ###x## # x##  #### x#### ### colors", IIf$(m.graphic_mode, "Graphics", "Text    "), @vbm.columns, @vbm.rows + 1, m.dots_per_char,  @vbm.char_height, m.width, m.height, m.num_colors) + $CrLf +_
            Using$("       Hfreq    = #.### kHz     Vfreq   = #.### Hz", m.hfreq / 1000, m.vfreq) + $CrLf +_
            Using$("       Buffer   = ###### bytes   Offset  = &h", @vbm.video_buffer_size, Hex$(m.offset, 4))
  Print #f, title0(mode_lab)

  Print #f, title1("Sequencer Registers")
  Print #f, Using$(" (01h) Clocking Mode                = &h (&b)", Hex$(@vbm.sequencer(0), 2), Bin$(@vbm.sequencer(0), 8))
  Print #f, Using$("       - Screen Disable             = #", Bit(@vbm.sequencer(0), 5))                + "______|||| |"
  Print #f, Using$("       - Shift 4 Enable             = #", Bit(@vbm.sequencer(0), 4))                + "_______||| |"
  Print #f, Using$("       - Dot Clock Rate             = #", Bit(@vbm.sequencer(0), 3))                + "________|| |"
  Print #f, Using$("       - Shift/Load Rate            = #", Bit(@vbm.sequencer(0), 2))                + "_________| |"
  Print #f, Using$("       - 9/8 Dot Mode (# dots/char) = #", m.dots_per_char, Bit(@vbm.sequencer(0), 0)) + "___________|"
  Print #f, Using$(" (02h) Map Mask Register            = &h (&b)", Hex$(@vbm.sequencer(1), 2), Bin$(@vbm.sequencer(1), 8))
  Print #f, Using$(" (03h) Character Map Select         = &h (&b)", Hex$(@vbm.sequencer(2), 2), Bin$(@vbm.sequencer(2), 8))
  Print #f, Using$("       - Character Set A            = &b", Bin$((@vbm.sequencer(2) And &b11) + (@vbm.sequencer(2) And &b10000) / 4, 3))
  Print #f, Using$("       - Character Set B            = &b", Bin$((@vbm.sequencer(2) And &b1100) / 4 + (@vbm.sequencer(2) And &b100000) / 8, 3))
  Print #f, Using$(" (04h) Memory Mode Register         = &h (&b)", Hex$(@vbm.sequencer(3), 2), Bin$(@vbm.sequencer(3), 8))

  Print #f, title1("Miscellaneous Output Register")
  Print #f, Using$(" (00h) Miscellaneous Output          = &h (&b)", Hex$(@vbm.miscellaneous, 2), Bin$(@vbm.miscellaneous, 8))
  Print #f, Using$("       - Vertical Sync Polarity  (&) =  #", IIf$(Bit(@vbm.miscellaneous, 7), "-", "+"), Bit(@vbm.miscellaneous, 7)) + "___||| ||||"
  Print #f, Using$("       - Horizontal Sync Polarity(&) =  #", IIf$(Bit(@vbm.miscellaneous, 6), "-", "+"), Bit(@vbm.miscellaneous, 6)) + "____|| ||||"
  Print #f, Using$("       - Odd/Even Page Select        =  #", Bit(@vbm.miscellaneous, 5))                                             + "_____| ||||"
  Print #f, Using$("       - Clock Select   (##.### MHz) = &", m.dotclock, Bin$(m.clock_select, 2))                                     + "_______||||"
  Print #f, Using$("       - Enable RAM                  =  #", Bit(@vbm.miscellaneous, 1))                                             + "_________||"
  Print #f, Using$("       - Input/Output Address Select =  #", Bit(@vbm.miscellaneous, 0))                                             + "__________|"

  Print #f, title1("CRTC Registers")
  Print #f, Using$(" (00h) Horizontal Total             = &h (###)", Hex$(@vbm.crtc(&h00), 2), m.horizontal_total)
  Print #f, Using$(" (01h) Horizontal Display End       = &h (###)", Hex$(@vbm.crtc(&h01), 2), m.horizontal_display_end)
  Print #f, Using$(" (02h) Horizontal Blanking Start    = &h (###)", Hex$(@vbm.crtc(&h02), 2), m.horizontal_blanking_start)
  Print #f, Using$(" (03h) Horizontal Blanking End      = &h (###)", Hex$(@vbm.crtc(&h03), 2), m.horizontal_blanking_end)
  Print #f, Using$(" (04h) Horizontal Retrace Start     = &h (###)", Hex$(@vbm.crtc(&h04), 2), m.horizontal_retrace_start)
  Print #f, Using$(" (05h) Horizontal Retrace End       = &h (###)", Hex$(@vbm.crtc(&h05), 2), m.horizontal_retrace_end)
  Print #f, Using$("       - Horizontal Retrace Skew    = #", (@vbm.crtc(&h05) And &b1100000) / 32)
  Print #f, Using$(" (06h) Vertical Total               = &h (###)", Hex$(@vbm.crtc(&h06), 2), m.vertical_total)
  Print #f, Using$(" (07h) Overflow                     = &h (&b)", Hex$(@vbm.crtc(&h07), 2), Bin$(@vbm.crtc(&h07), 8))
  Print #f, Using$(" (08h) Preset Row Scan              = &h (&b)", Hex$(@vbm.crtc(&h08), 2), Bin$(@vbm.crtc(&h08), 8))
  Print #f, Using$(" (09h) Maximum Scan Line            = &h (&b)", Hex$(@vbm.crtc(&h09), 2), Bin$(@vbm.crtc(&h09), 8))
  Print #f, Using$("       - Scan Doubling              = #", Bit(@vbm.crtc(&h09), 7)) + "____||||||||"
  Print #f, Using$("       - Line Compare Bit-9         = #", Bit(@vbm.crtc(&h09), 6)) + "_____|||||||"
  Print #f, Using$("       - Start V. Blanking Bit-9    = #", Bit(@vbm.crtc(&h09), 5)) + "______||||||"
  Print #f, Using$("       - Maximum Scan Line          = #", m.maximum_scan_line)     + "_______|||||"
  Print #f, Using$(" (0Ah) Cursor Start                 = &h (###) &", Hex$(@vbm.crtc(&h0a), 2), (@vbm.crtc(&h0A) And &b11111), IIf$((@vbm.crtc(&h0A) And &b100000), "", " cursor enabled"))
  Print #f, Using$(" (0Bh) Cursor End                   = &h (###)", Hex$(@vbm.crtc(&h0b), 2), (@vbm.crtc(&h0B) And &b11111))
  Print #f, Using$(" (0Ch) Start Address High           = &h (###)", Hex$(@vbm.crtc(&h0c), 2), @vbm.crtc(&h0c))
  Print #f, Using$(" (0Dh) Start Address Low            = &h (###)", Hex$(@vbm.crtc(&h0d), 2), @vbm.crtc(&h0d))
  Print #f, Using$(" (0Eh) Cursor Location High         = &h (###)", Hex$(@vbm.crtc(&h0e), 2), @vbm.crtc(&h0e))
  Print #f, Using$(" (0Fh) Cursor Location Low          = &h (###)", Hex$(@vbm.crtc(&h0f), 2), @vbm.crtc(&h0f))
  Print #f, Using$(" (10h) Vertical Retrace Start       = &h (###)", Hex$(@vbm.crtc(&h10), 2), m.vertical_retrace_start)
  Print #f, Using$(" (11h) Vertical Retrace End         = &h (###)", Hex$(@vbm.crtc(&h11), 2), m.vertical_retrace_end)
  Print #f, Using$(" (12h) Vertical Display End         = &h (###)", Hex$(@vbm.crtc(&h12), 2), m.vertical_display_end)
  Print #f, Using$(" (13h) Offset                       = &h (###)", Hex$(@vbm.crtc(&h13), 2), @vbm.crtc(&h13))
  Print #f, Using$(" (14h) Underline Location           = &h (###) &", Hex$(@vbm.crtc(&h14), 2), (@vbm.crtc(&h14) And &b11111), IIf$((@vbm.crtc(&h14) And &b100000), " div4", "") + IIf$((@vbm.crtc(&h14) And &b1000000), " dword", ""))
  Print #f, Using$(" (15h) Vertical Blanking Start      = &h (###)", Hex$(@vbm.crtc(&h15), 2), m.vertical_blanking_start)
  Print #f, Using$(" (16h) Vertical Blanking End        = &h (###)", Hex$(@vbm.crtc(&h16), 2), m.vertical_blanking_end)
  Print #f, Using$(" (17h) Mode Control Register        = &h (&b)", Hex$(@vbm.crtc(&h17), 2), Bin$(@vbm.crtc(&h17), 8))
  Print #f, Using$("       - Hardware Reset             = #", Bit(@vbm.crtc(&h17), 7)) + "____||| ||||"
  Print #f, Using$("       - Word/Byte Mode             = #", Bit(@vbm.crtc(&h17), 6)) + "_____|| ||||"
  Print #f, Using$("       - Address Wrap               = #", Bit(@vbm.crtc(&h17), 5)) + "______| ||||"
  Print #f, Using$("       - Count by Two               = #", Bit(@vbm.crtc(&h17), 3)) + "________||||"
  Print #f, Using$("       - Horizontal Retrace Select  = #", Bit(@vbm.crtc(&h17), 2)) + "_________|||"
  Print #f, Using$("       - Select Row Scan Counter    = #", Bit(@vbm.crtc(&h17), 1)) + "__________||"
  Print #f, Using$("       - Compatibility Mode Support = #", Bit(@vbm.crtc(&h17), 0)) + "___________|"
  Print #f, Using$(" (18h) Line Compare                 = &h (&h)", Hex$(@vbm.crtc(&h18), 2), Hex$(m.line_compare))

  Print #f, title1("Attribute Controller Registers")
  Print #f, Using$(" (00h-03h) Palette                  = &h &h &h &h", Hex$(@vbm.attribute(&h00), 2), Hex$(@vbm.attribute(&h01), 2), Hex$(@vbm.attribute(&h02), 2), Hex$(@vbm.attribute(&h03), 2))
  Print #f, Using$(" (04h-07h) Palette                  = &h &h &h &h", Hex$(@vbm.attribute(&h04), 2), Hex$(@vbm.attribute(&h05), 2), Hex$(@vbm.attribute(&h06), 2), Hex$(@vbm.attribute(&h07), 2))
  Print #f, Using$(" (08h-0Bh) Palette                  = &h &h &h &h", Hex$(@vbm.attribute(&h08), 2), Hex$(@vbm.attribute(&h09), 2), Hex$(@vbm.attribute(&h0a), 2), Hex$(@vbm.attribute(&h0b), 2))
  Print #f, Using$(" (0Ch-0Fh) Palette                  = &h &h &h &h", Hex$(@vbm.attribute(&h0c), 2), Hex$(@vbm.attribute(&h0d), 2), Hex$(@vbm.attribute(&h0e), 2), Hex$(@vbm.attribute(&h0f), 2))
  Print #f, Using$(" (10h) Mode Control                 = &h (&b)", Hex$(@vbm.attribute(&h10), 2), Bin$(@vbm.attribute(&h10), 8))
  Print #f, Using$("       - Palette Bits 5-4 Select    = #", Bit(@vbm.attribute(&h10), 7)) + "____||| ||||"
  Print #f, Using$("       - 8-bit Color Enable         = #", Bit(@vbm.attribute(&h10), 6)) + "_____|| ||||"
  Print #f, Using$("       - Pixel Panning Mode         = #", Bit(@vbm.attribute(&h10), 5)) + "______| ||||"
  Print #f, Using$("       - Blink Enable               = #", Bit(@vbm.attribute(&h10), 3)) + "________||||"
  Print #f, Using$("       - Line Graphics Enable       = #", Bit(@vbm.attribute(&h10), 2)) + "_________|||"
  Print #f, Using$("       - Monochrome Emulation       = #", Bit(@vbm.attribute(&h10), 1)) + "__________||"
  Print #f, Using$("       - Attr. Ctr. Graphics Enable = #", Bit(@vbm.attribute(&h10), 0)) + "___________|"
  Print #f, Using$(" (11h) Overscan                     = &h", Hex$(@vbm.attribute(&h11), 2))
  Print #f, Using$(" (12h) Color Plane Enable           = &h (&b)", Hex$(@vbm.attribute(&h12), 2), Bin$(@vbm.attribute(&h12), 8))
  Print #f, Using$(" (13h) Horizontal Pel Panning       = &h (&b)", Hex$(@vbm.attribute(&h13), 2), Bin$(@vbm.attribute(&h13), 8))

  Print #f, title1("Graphics Registers")
  Print #f, Using$(" (00h) Set/Reset                    = &h (&b)", Hex$(@vbm.graphics(0), 2), Bin$(@vbm.graphics(0) And &b1111, 8))
  Print #f, Using$(" (01h) Enable Set/Reset             = &h (&b)", Hex$(@vbm.graphics(1), 2), Bin$(@vbm.graphics(1) And &b1111, 8))
  Print #f, Using$(" (02h) Color Compare                = &h (&b)", Hex$(@vbm.graphics(2), 2), Bin$(@vbm.graphics(2) And &b1111, 8))
  Print #f, Using$(" (03h) Data Rotate                  = &h (&b)", Hex$(@vbm.graphics(3), 2), Bin$(@vbm.graphics(3), 8))
  Print #f, Using$(" (04h) Read Map Select              = &h (&b)", Hex$(@vbm.graphics(4), 2), Bin$(@vbm.graphics(4), 8))
  Print #f, Using$(" (05h) Graphics Mode                = &h (&b)", Hex$(@vbm.graphics(5), 2), Bin$(@vbm.graphics(5), 8))
  Print #f, Using$(" (06h) Miscellaneous Graphics       = &h (&b)", Hex$(@vbm.graphics(6), 2), Bin$(@vbm.graphics(6), 8))
  Print #f, Using$(" (07h) Color Don't Care             = &h (&b)", Hex$(@vbm.graphics(7), 2), Bin$(@vbm.graphics(7), 8))
  Print #f, Using$(" (08h) Bit Mask                     = &h (&b)", Hex$(@vbm.graphics(8), 2), Bin$(@vbm.graphics(8), 8))
  Print #f, $CrLf

  Function = 1
End Function

'============================================================
'  standard_mode_reprogram
'============================================================

Function standard_mode_reprogram(ByVal vbm As VBIOS_MODE Ptr, m As VIDEO_MODE_DEF) As Long

  Select Case m.bios_num
    Case &h00, &h01
      If range_31 And modedef_adjust(m, range_31, 9, 16, %CLOCK_14161, 40, 43, 50,  50, 400, %SCAN_TEXT) Then success
      If range_25 And modedef_adjust(m, range_25, 9, 14, %CLOCK_14161, 40, 47, 54,  63, 400, %SCAN_TEXT) Then success
      If range_15 And modedef_adjust(m, range_15, 8,  8, %CLOCK_12587, 40, 68, 72, 100, 200, %SCAN_TEXT) Then success

    Case &h02, &h03, &h07
      If range_31 And modedef_adjust(m, range_31, 9, 16, %CLOCK_28322, 80, 85, 97, 100, 400, %SCAN_TEXT) Then success
      If range_25 And modedef_adjust(m, range_25, 9, 14, %CLOCK_25175, 80, 90, 99, 112, 400, %SCAN_TEXT) Then success
      If range_15 And modedef_adjust(m, range_15, 8,  8, %CLOCK_12587, 80, 85, 97, 100, 200, %SCAN_TEXT) Then success

    Case &h04, &h05
      If range_31 And modedef_adjust(m, range_31, 8, 8, %CLOCK_12587, 40, 43, 50,  50, 400, %SCAN_TYPE_3) Then success
      If range_25 And modedef_adjust(m, range_25, 8, 8, %CLOCK_12587, 40, 47, 54,  63, 400, %SCAN_TYPE_3) Then success
      If range_15 And modedef_adjust(m, range_15, 8, 8, %CLOCK_12587, 40, 68, 72, 100, 200, %SCAN_TYPE_1) Then success

    Case &h06
      If range_31 And modedef_adjust(m, range_31, 8, 8, %CLOCK_25175, 80, 84,  96, 100, 400, %SCAN_TYPE_3) Then success
      If range_25 And modedef_adjust(m, range_25, 8, 8, %CLOCK_25175, 80, 95, 110, 126, 400, %SCAN_TYPE_3) Then success
      If range_15 And modedef_adjust(m, range_15, 8, 8, %CLOCK_12587, 80, 84,  96, 100, 200, %SCAN_TYPE_1) Then success

    Case &h0D
      If range_31 And modedef_adjust(m, range_31, 8, 8, %CLOCK_12587, 40, 43,  68,  50, 400, %SCAN_TYPE_2) Then success
      If range_25 And modedef_adjust(m, range_25, 8, 8, %CLOCK_12587, 40, 47,  54,  63, 400, %SCAN_TYPE_2) Then success
      If range_15 And modedef_adjust(m, range_15, 8, 8, %CLOCK_12587, 40, 68,  72, 100, 200, %SCAN_TYPE_0) Then success

    Case &h0E
      If range_31 And modedef_adjust(m, range_31, 8, 8, %CLOCK_25175, 80, 84,  96, 100, 400, %SCAN_TYPE_2) Then success
      If range_25 And modedef_adjust(m, range_25, 8, 8, %CLOCK_25175, 80, 95, 110, 126, 400, %SCAN_TYPE_2) Then success
      If range_15 And modedef_adjust(m, range_15, 8, 8, %CLOCK_12587, 80, 84,  96, 100, 200, %SCAN_TYPE_0) Then success

    Case &h0F, &h10
      If range_31 And modedef_adjust(m, range_31, 8, 14, %CLOCK_25175, 80, 84,  96, 100, 350, %SCAN_TYPE_0) Then success
      If range_25 And modedef_adjust(m, range_25, 8, 14, %CLOCK_25175, 80, 95, 110, 126, 350, %SCAN_TYPE_0) Then success
      If range_15 And modedef_adjust(m, range_15, 8, 14, %CLOCK_12587, 80, 84,  96, 100, 350, %SCAN_TYPE_0 Or %SCAN_INTERLACE) Then success

    Case &h11, &h12
      If range_31 And modedef_adjust(m, range_31, 8, 16, %CLOCK_25175, 80, 84,  96, 100, 480, %SCAN_TYPE_0) Then success
      If range_25 And modedef_adjust(m, range_25, 8, 16, %CLOCK_25175, 80, 95, 110, 126, 480, %SCAN_TYPE_0 Or %SCAN_INTERLACE) Then success
      If range_15 And modedef_adjust(m, range_15, 8, 16, %CLOCK_12587, 80, 84,  96, 100, 480, %SCAN_TYPE_0 Or %SCAN_INTERLACE) Then success

    Case &h13
      If range_31 And modedef_adjust(m, range_31, 8, 8, %CLOCK_25175, 80, 84,  96, 100, 400, %SCAN_TYPE_1) Then success
      If range_25 And modedef_adjust(m, range_25, 8, 8, %CLOCK_25175, 80, 95, 110, 126, 400, %SCAN_TYPE_1) Then success
      If range_15 And modedef_adjust(m, range_15, 8, 8, %CLOCK_12587, 80, 84,  96, 100, 200, %SCAN_TYPE_0) Then success

    Case Else
      exit_error(Using$("Unknown mode number &h.", Hex$(m.bios_num)))

  End Select

  exit_error(Using$("Out of range when trying to reprogram mode &h.", Hex$(m.bios_num)))

  success:

  standard_mode_from_modedef(vbm, m)

  Function = 1
End Function

'============================================================
'  modedef_adjust
'============================================================

Function modedef_adjust(m As VIDEO_MODE_DEF, ByVal r As MONITOR_RANGE Ptr, c_dots As Long, c_lines As Long, clock_select As Long, hh As Long, hs As Long, he As Long, ht As Long, vv As Long, scan_type As Long) As Long

  Local interlace, double_scan As Long
  Local field_active, field_total, field_blank, field_padding As Double

  m.dots_per_char = c_dots
  m.lines_per_char = c_lines

  If (scan_type And %SCAN_TEXT) Then
    m.scan_doubling     = 0
    m.maximum_scan_line = m.lines_per_char - 1
    m.cursor_end        = m.maximum_scan_line - 1
    m.cursor_start      = m.cursor_end - 1
  Else
    Select Case scan_type And &h07f
      Case %SCAN_TYPE_0
        m.scan_doubling     = 0
        m.maximum_scan_line = 0
        double_scan         = 0
      Case %SCAN_TYPE_1
        m.scan_doubling     = 0
        m.maximum_scan_line = 1
        double_scan         = 1
      Case %SCAN_TYPE_2
        m.scan_doubling     = 1
        m.maximum_scan_line = 0
        double_scan         = 1
      Case %SCAN_TYPE_3
        m.scan_doubling     = 1
        m.maximum_scan_line = 1
        double_scan         = 1
    End Select
  End If

  m.interlace = IIf((scan_type And %SCAN_INTERLACE), 1 , 0)
  interlace = IIf(m.interlace, 2, 1)

  m.horizontal_display_end    = hh - 1
  m.horizontal_retrace_start  = hs
  m.horizontal_retrace_end    = he
  m.horizontal_total          = ht
  m.horizontal_blanking_start = hh + 1
  m.horizontal_blanking_end   = ht - 1

  m.clock_select = clock_select And &h07f
  m.dotclock_div = IIf((clock_select And %CLOCK_DIV_2), 1, 0)
  m.dotclock = clock(m.clock_select)

  m.hfreq = (m.dotclock / IIf(m.dotclock_div, 2, 1)) * 1000000 / (m.horizontal_total * m.dots_per_char)
  m.vfreq = Min(m.hfreq / (vv / interlace + Round(m.hfreq * @r.vertical_blank, 0)), @r.v_freq_max)
  If m.vfreq < @r.v_freq_min Then Exit Function

  field_active = vv / interlace
  field_total = Round(m.hfreq / m.vfreq, 0) + IIf(interlace = 2, 0.5, 0)
  field_blank = (Int(m.hfreq * @r.vertical_blank) + IIf (interlace = 2, 0.5, 0))
  field_padding = field_total - field_blank - field_active

  m.vertical_display_end   = vv
  m.vertical_retrace_start = vv + (Max(Round(m.hfreq * @r.v_front_porch, 0), 1) + field_padding / 2)  * interlace
  m.vertical_retrace_end = m.vertical_retrace_start + Max(Round(m.hfreq * @r.v_sync_pulse, 0), 1)  * interlace
  m.vertical_total = field_total * interlace
  m.vertical_blanking_start = vv + 1
  m.vertical_blanking_end = m.vertical_total - 1

  m.hsync_polarity = IIf(composite_sync, 1, @r.h_sync_polarity)
  m.vsync_polarity = IIf(composite_sync, 1, @r.v_sync_polarity)

  Function = 1
End Function

'============================================================
'  process_vesa_modes
'============================================================

Function process_vesa_modes(b As ATOMBIOS, action As Long) As Long

  Local i, j, r As Long
  Local m As Long Ptr
  Local u, v As ATOM_VESA_TO_EXTENDED_MODE Ptr
  Local mdln As MODELINE
  Local mode_label, cols As String
  Local f As Long
  f = b.log_file_handle

  Print #f, title1("Supported VESA modes")

  If (action And %REPROGRAM) Then
    For i = 0 To b.num_of_vesa_timings - 1
      Reset mdln
      vesa_timing_reprogram(b, i, mdln)
    Next
  End If

  For i = 0 To b.num_of_vesa_modes - 1
    v = VarPtr(b.@vesa_to_internal_mode_ptr.asVESA_ToExtendedModeInfo(i))
    If @v.usVESA_ModeNumber Then
      Print #f, Hex$(@v.usVESA_ModeNumber) + "h - ";
      m = vesa_timing_get_ptr(b, @v.usExtendedModeNumber)
      Reset mdln
      If m Then
        vesa_timing_to_modeline(b, m, mdln)
        If (action And %REPROGRAM) Then b.reprogram_table.vesa(@v.usVESA_ModeNumber - &h100) = IIf(mdln.interlace, %INTERLACE_ENABLE, 0)
        Select Case (@v.usExtendedModeNumber And &hff)
          Case  2 : cols = "256"
          Case  6 : cols = "32K"
          Case 22 : cols = "65K"
          Case 10 : cols = "16M"
        End Select
        u = VarPtr(b.@vesa_to_internal_mode_ptr.asVESA_ToExtendedModeInfo(j))
        @u = @v
        Incr j
        mode_label = Using$("#### x#### @ ## & colors - index: &h timing: &h", mdln.width, mdln.height, mdln.refresh, cols, Hex$(v - b.bios_ptr, 4), Hex$(m - b.bios_ptr, 4))
      Else
        Reset @v
        mode_label = "Disabled"
      End If
      Print #f, mode_label
    End If
  Next

  ' Blank unused entries
  If (action And %REPROGRAM) Then
    For i = j To b.num_of_vesa_modes - 1
      u = VarPtr(b.@vesa_to_internal_mode_ptr.asVESA_ToExtendedModeInfo(i))
      @u.usVESA_ModeNumber = &h0ffff
      @u.usExtendedModeNumber = &h0ffff
    Next
    b.@vesa_to_internal_mode_ptr.sHeader.usStructureSize = j * SizeOf(ATOM_VESA_TO_EXTENDED_MODE) + SizeOf(ATOM_COMMON_TABLE_HEADER)
  End If

  If (action And %SHOW_INFO) Then
    For i = 0 To b.num_of_vesa_timings - 1
      vesa_timing_show_info(b, i, b.log_file_handle)
    Next
  End If

End Function

'============================================================
'  vesa_timing_get_ptr
'============================================================

Function vesa_timing_get_ptr(b As ATOMBIOS, timing_num As Word) As Long

  Local m As ATOM_MODE_TIMING Ptr
  Local n As ATOM_DTD_FORMAT Ptr
  Local i, this_num, interlace As Long

  For i = 0 To b.num_of_vesa_timings - 1
    If b.vesa_old_format Then
      m = VarPtr(b.@standard_vesa_timing_ptr.aModeTimings.old(i))
      this_num = @m.ucInternalModeNumber
      Function = m
    Else
      n = VarPtr(b.@standard_vesa_timing_ptr.aModeTimings.new(i))
      this_num = @n.ucInternalModeNumber
      Function = n
    End If
    If this_num = Int(timing_num / 256) Then found
  Next

  Function = 0
  Exit Function
  found:

End Function

'============================================================
'  vesa_timing_show_info
'============================================================

Function vesa_timing_show_info(b As ATOMBIOS, index As Long, f As Long) As Long

  Local m As ATOM_MODE_TIMING Ptr
  Local n As ATOM_DTD_FORMAT Ptr
  Local hfreq, vfreq As Double

  If b.vesa_old_format Then
    m = VarPtr(b.@standard_vesa_timing_ptr.aModeTimings.old(index))
    If IsFalse @m.ucInternalModeNumber Then Exit Function
    hfreq = @m.usPixelClock * 10000 / (@m.usCRTC_H_Total)
    vfreq = hfreq / @m.usCRTC_V_Total * IIf(Bit(@m.susModeMiscInfo.usAccess, 7), 2, 1)
    Print #f, title1(Using$("Mode # x # @ # (#.### Hz, #.### kHz)", @m.usCRTC_H_Disp, @m.usCRTC_V_Disp, @m.ucRefreshRate, vfreq, hfreq / 1000))
    Print #f, Using$(" CRTC H Total         = &h (#####)", Hex$(@m.usCRTC_H_Total, 4), @m.usCRTC_H_Total)
    Print #f, Using$(" CRTC H Disp          = &h (#####)", Hex$(@m.usCRTC_H_Disp, 4), @m.usCRTC_H_Disp)
    Print #f, Using$(" CRTC H SyncStart     = &h (#####)", Hex$(@m.usCRTC_H_SyncStart, 4), @m.usCRTC_H_SyncStart)
    Print #f, Using$(" CRTC H SyncWidth     = &h (#####)", Hex$(@m.usCRTC_H_SyncWidth, 4), @m.usCRTC_H_SyncWidth)
    Print #f, Using$(" CRTC V Total         = &h (#####)", Hex$(@m.usCRTC_V_Total, 4), @m.usCRTC_V_Total)
    Print #f, Using$(" CRTC V Disp          = &h (#####)", Hex$(@m.usCRTC_V_Disp, 4), @m.usCRTC_V_Disp)
    Print #f, Using$(" CRTC V SyncStart     = &h (#####)", Hex$(@m.usCRTC_V_SyncStart, 4), @m.usCRTC_V_SyncStart)
    Print #f, Using$(" CRTC V SyncWidth     = &h (#####)", Hex$(@m.usCRTC_V_SyncWidth, 4), @m.usCRTC_V_SyncWidth)
    Print #f, Using$(" Pixel Clock          = &h (#####)", Hex$(@m.usPixelClock, 4), @m.usPixelClock)
    Print #f, Using$(" Mode Misc Info       = &h (&b)", Hex$(@m.susModeMiscInfo.usAccess, 4), Bin$(@m.susModeMiscInfo.usAccess, 16))
    Print #f, Using$(" - Reserved           = &", "x")                                 + "______||||||||||||||||"
    Print #f, Using$(" - RGB888             = #", Bit(@m.susModeMiscInfo.usAccess, 9)) + "____________||||||||||"
    Print #f, Using$(" - Double Clock       = #", Bit(@m.susModeMiscInfo.usAccess, 8)) + "_____________|||||||||"
    Print #f, Using$(" - Interlace          = #", Bit(@m.susModeMiscInfo.usAccess, 7)) + "______________||||||||"
    Print #f, Using$(" - Composite Sync     = #", Bit(@m.susModeMiscInfo.usAccess, 6)) + "_______________|||||||"
    Print #f, Using$(" - V Replication by 2 = #", Bit(@m.susModeMiscInfo.usAccess, 5)) + "________________||||||"
    Print #f, Using$(" - H Replication by 2 = #", Bit(@m.susModeMiscInfo.usAccess, 4)) + "_________________|||||"
    Print #f, Using$(" - Vertical Cut Off   = #", Bit(@m.susModeMiscInfo.usAccess, 3)) + "__________________||||"
    Print #f, Using$(" - V Sync Polarity (&)= #", IIf$(Bit(@m.susModeMiscInfo.usAccess, 2), "-", "+"), Bit(@m.susModeMiscInfo.usAccess, 2)) + "___________________|||"
    Print #f, Using$(" - H Sync Polarity (&)= #", IIf$(Bit(@m.susModeMiscInfo.usAccess, 1), "-", "+"), Bit(@m.susModeMiscInfo.usAccess, 1)) + "____________________||"
    Print #f, Using$(" - Horizontal Cut Off = #", Bit(@m.susModeMiscInfo.usAccess, 0)) + "_____________________|"
    Print #f, Using$(" CRTC Overscan Right  = &h (#####)", Hex$(@m.usCRTC_OverscanRight, 4), @m.usCRTC_OverscanRight)
    Print #f, Using$(" CRTC Overscan Left   = &h (#####)", Hex$(@m.usCRTC_OverscanLeft, 4), @m.usCRTC_OverscanLeft)
    Print #f, Using$(" CRTC Overscan Bottom = &h (#####)", Hex$(@m.usCRTC_OverscanBottom, 4), @m.usCRTC_OverscanBottom)
    Print #f, Using$(" CRTC Overscan Top    = &h (#####)", Hex$(@m.usCRTC_OverscanTop, 4), @m.usCRTC_OverscanTop)
    Print #f, Using$(" usReserve            = &h (#####)", Hex$(@m.usReserve, 4), @m.usReserve)
    Print #f, Using$(" Internal Mode Number =   &h (#####)", Hex$(@m.ucInternalModeNumber, 2), @m.ucInternalModeNumber)
    Print #f, Using$(" Refresh Rate         =   &h (#####)", Hex$(@m.ucRefreshRate, 2), @m.ucRefreshRate)
    Print #f

  Else
    n = VarPtr(b.@standard_vesa_timing_ptr.aModeTimings.new(index))
    If IsFalse @n.ucInternalModeNumber Then Exit Function
    hfreq = @n.usPixClk * 10000 / (@n.usHActive + @n.usHBlanking_Time)
    vfreq = hfreq / (@n.usVActive + @n.usVBlanking_Time) * IIf(Bit(@n.susModeMiscInfo.usAccess, 7), 2, 1)
    Print #f, title1(Using$("Mode # x # @ # (#.### Hz, #.### kHz)", @n.usHActive, @n.usVActive, @n.ucRefreshRate, vfreq, hfreq / 1000))
    Print #f, Using$(" Pixel Clock          = &h (#####)", Hex$(@n.usPixClk, 4), @n.usPixClk)
    Print #f, Using$(" HActive              = &h (#####)", Hex$(@n.usHActive, 4), @n.usHActive)
    Print #f, Using$(" HBlanking Time       = &h (#####)", Hex$(@n.usHBlanking_Time, 4), @n.usHBlanking_Time)
    Print #f, Using$(" VActive              = &h (#####)", Hex$(@n.usVActive, 4), @n.usVActive)
    Print #f, Using$(" VBlanking Time       = &h (#####)", Hex$(@n.usVBlanking_Time, 4), @n.usVBlanking_Time)
    Print #f, Using$(" HSync Offset         = &h (#####)", Hex$(@n.usHSyncOffset, 4), @n.usHSyncOffset)
    Print #f, Using$(" HSync Width          = &h (#####)", Hex$(@n.usHSyncWidth, 4), @n.usHSyncWidth)
    Print #f, Using$(" VSync Offset         = &h (#####)", Hex$(@n.usVSyncOffset, 4), @n.usVSyncOffset)
    Print #f, Using$(" VSync Width          = &h (#####)", Hex$(@n.usVSyncWidth, 4), @n.usVSyncWidth)
    Print #f, Using$(" Image HSize          = &h (#####)", Hex$(@n.usImageHSize, 4), @n.usImageHSize)
    Print #f, Using$(" Image VSize          = &h (#####)", Hex$(@n.usImageVSize, 4), @n.usImageVSize)
    Print #f, Using$(" HBorder              =   &h (#####)", Hex$(@n.ucHBorder, 2), @n.ucHBorder)
    Print #f, Using$(" VBorder              =   &h (#####)", Hex$(@n.ucVBorder, 2), @n.ucVBorder)
    Print #f, Using$(" Mode Misc Info       = &h (&b)", Hex$(@n.susModeMiscInfo.usAccess, 4), Bin$(@n.susModeMiscInfo.usAccess, 16))
    Print #f, Using$(" - Reserved           = &", "x")                                 + "______||||||||||||||||"
    Print #f, Using$(" - RGB888             = #", Bit(@n.susModeMiscInfo.usAccess, 9)) + "____________||||||||||"
    Print #f, Using$(" - Double Clock       = #", Bit(@n.susModeMiscInfo.usAccess, 8)) + "_____________|||||||||"
    Print #f, Using$(" - Interlace          = #", Bit(@n.susModeMiscInfo.usAccess, 7)) + "______________||||||||"
    Print #f, Using$(" - Composite Sync     = #", Bit(@n.susModeMiscInfo.usAccess, 6)) + "_______________|||||||"
    Print #f, Using$(" - V Replication by 2 = #", Bit(@n.susModeMiscInfo.usAccess, 5)) + "________________||||||"
    Print #f, Using$(" - H Replication by 2 = #", Bit(@n.susModeMiscInfo.usAccess, 4)) + "_________________|||||"
    Print #f, Using$(" - Vertical Cut Off   = #", Bit(@n.susModeMiscInfo.usAccess, 3)) + "__________________||||"
    Print #f, Using$(" - V Sync Polarity (&)= #", IIf$(Bit(@n.susModeMiscInfo.usAccess, 2), "-", "+"), Bit(@n.susModeMiscInfo.usAccess, 2)) + "___________________|||"
    Print #f, Using$(" - H Sync Polarity (&)= #", IIf$(Bit(@n.susModeMiscInfo.usAccess, 1), "-", "+"), Bit(@n.susModeMiscInfo.usAccess, 1)) + "____________________||"
    Print #f, Using$(" - Horizontal Cut Off = #", Bit(@n.susModeMiscInfo.usAccess, 0)) + "_____________________|"
    Print #f, Using$(" Internal Mode Number =   &h (#####)", Hex$(@n.ucInternalModeNumber, 2), @n.ucInternalModeNumber)
    Print #f, Using$(" Refresh Rate         =   &h (#####)", Hex$(@n.ucRefreshRate, 2), @n.ucRefreshRate)
    Print #f

  End If

  Function = 1
End Function

'============================================================
'  vesa_timing_reprogram
'============================================================

Function vesa_timing_reprogram(b As ATOMBIOS, index As Long, mdln As MODELINE) As Long

  Local m As Long Ptr

  If b.vesa_old_format Then
    m = VarPtr(b.@standard_vesa_timing_ptr.aModeTimings.old(index))
  Else
    m = VarPtr(b.@standard_vesa_timing_ptr.aModeTimings.new(index))
  End If

  If mdln.height Then
    GoTo success

  Else
    vesa_timing_to_modeline(b, m, mdln)

    Select Case mdln.height
      Case 200, 240
        If range_15 And modeline_adjust(mdln, range_15) Then success
        If range_31 And modeline_adjust(mdln, range_31) Then success
      Case 350, 384, 768
        If range_25 And modeline_adjust(mdln, range_25) Then success
        If range_31 And modeline_adjust(mdln, range_31) Then success
      Case 400, 480, 600
        If range_31 And modeline_adjust(mdln, range_31) Then success
        If range_25 And modeline_adjust(mdln, range_25) Then success
        If range_15 And modeline_adjust(mdln, range_15) Then success
      Case 864, 960
        If range_31 And modeline_adjust(mdln, range_31) Then success
    End Select
  End If

  ' If not adjustable, disable this timing
  vesa_timing_disable(b, m)
  Exit Function

  success:

  vesa_timing_from_modeline(b, m, mdln)
  Function = 1
End Function

'============================================================
'  vesa_timing_to_modeline
'============================================================

Function vesa_timing_to_modeline(b As ATOMBIOS, ByVal p As Long Ptr, mdln As MODELINE) As Long

  Local m As ATOM_MODE_TIMING Ptr
  Local n As ATOM_DTD_FORMAT Ptr

  If b.vesa_old_format Then
    m = p
    mdln.pclock     = @m.usPixelClock
    mdln.htotal     = @m.usCRTC_H_Total
    mdln.hactive    = @m.usCRTC_H_Disp
    mdln.hbegin     = @m.usCRTC_H_SyncStart
    mdln.hend       = @m.usCRTC_H_SyncStart + @m.usCRTC_H_SyncWidth
    mdln.vtotal     = @m.usCRTC_V_Total
    mdln.vactive    = @m.usCRTC_V_Disp
    mdln.vbegin     = @m.usCRTC_V_SyncStart
    mdln.vend       = @m.usCRTC_V_SyncStart + @m.usCRTC_V_SyncWidth
    mdln.interlace  = Bit(@m.susModeMiscInfo.usAccess, 7)
    mdln.doublescan = Bit(@m.susModeMiscInfo.usAccess, 5)
    mdln.hsync      = Bit(@m.susModeMiscInfo.usAccess, 1) Xor 1
    mdln.vsync      = Bit(@m.susModeMiscInfo.usAccess, 2) Xor 1
    mdln.refresh    = @m.ucRefreshRate
    mdln.number     = @m.ucInternalModeNumber
  Else
    n = p
    mdln.pclock     = @n.usPixClk
    mdln.htotal     = @n.usHActive + @n.usHBlanking_Time
    mdln.hactive    = @n.usHActive
    mdln.hbegin     = @n.usHActive + @n.usHSyncOffset
    mdln.hend       = @n.usHActive + @n.usHSyncOffset + @n.usHSyncWidth
    mdln.vtotal     = @n.usVActive + @n.usVBlanking_Time
    mdln.vactive    = @n.usVActive
    mdln.vbegin     = @n.usVActive + @n.usVSyncOffset
    mdln.vend       = @n.usVActive + @n.usVSyncOffset + @n.usVSyncWidth
    mdln.interlace  = Bit(@n.susModeMiscInfo.usAccess, 7)
    mdln.doublescan = Bit(@n.susModeMiscInfo.usAccess, 5)
    mdln.hsync      = Bit(@n.susModeMiscInfo.usAccess, 1) Xor 1
    mdln.vsync      = Bit(@n.susModeMiscInfo.usAccess, 2) Xor 1
    mdln.refresh    = @n.ucRefreshRate
    mdln.number     = @n.ucInternalModeNumber
  End If

  mdln.hfreq  = mdln.pclock * 10000 / mdln.htotal
  mdln.vfreq  = mdln.hfreq / mdln.vtotal * IIf(mdln.interlace, 2, 1)
  mdln.width  = mdln.hactive
  mdln.height = mdln.vactive

End Function

'============================================================
'  vesa_timing_from_modeline
'============================================================

Function vesa_timing_from_modeline(b As ATOMBIOS, ByVal p As Long Ptr, mdln As MODELINE) As Long

  Local m As ATOM_MODE_TIMING Ptr
  Local n As ATOM_DTD_FORMAT Ptr

  If b.vesa_old_format Then
    m = p
    Reset @m
    @m.usPixelClock       = mdln.pclock
    @m.usCRTC_H_Total     = mdln.htotal
    @m.usCRTC_H_Disp      = mdln.hactive
    @m.usCRTC_H_SyncStart = mdln.hbegin
    @m.usCRTC_H_SyncWidth = mdln.hend - mdln.hbegin
    @m.usCRTC_V_Total     = mdln.vtotal
    @m.usCRTC_V_Disp      = mdln.vactive
    @m.usCRTC_V_SyncStart = mdln.vbegin
    @m.usCRTC_V_SyncWidth = mdln.vend - mdln.vbegin
    @m.susModeMiscInfo.usAccess Or= IIf(mdln.interlace, %ATOM_INTERLACE, 0)
    @m.susModeMiscInfo.usAccess Or= IIf(mdln.doublescan, %ATOM_V_REPLICATIONBY2, 0)
    @m.susModeMiscInfo.usAccess Or= IIf(mdln.hsync, 0, %ATOM_HSYNC_POLARITY)
    @m.susModeMiscInfo.usAccess Or= IIf(mdln.vsync, 0, %ATOM_VSYNC_POLARITY)
    @m.ucRefreshRate = mdln.refresh
    @m.ucInternalModeNumber = mdln.number
  Else
    n = p
    Reset @n
    @n.usPixClk         = mdln.pclock
    @n.usHActive        = mdln.hactive
    @n.usHBlanking_Time = mdln.htotal - mdln.hactive
    @n.usVActive        = mdln.vactive
    @n.usVBlanking_Time = mdln.vtotal - mdln.vactive
    @n.usHSyncOffset    = mdln.hbegin - mdln.hactive
    @n.usHSyncWidth     = mdln.hend - mdln.hbegin
    @n.usVSyncOffset    = mdln.vbegin - mdln.vactive
    @n.usVSyncWidth     = mdln.vend - mdln.vbegin
    @n.susModeMiscInfo.usAccess Or= IIf(mdln.interlace, %ATOM_INTERLACE, 0)
    @n.susModeMiscInfo.usAccess Or= IIf(mdln.doublescan, %ATOM_V_REPLICATIONBY2, 0)
    @n.susModeMiscInfo.usAccess Or= IIf(mdln.hsync, 0, %ATOM_HSYNC_POLARITY)
    @n.susModeMiscInfo.usAccess Or= IIf(mdln.vsync, 0, %ATOM_VSYNC_POLARITY)
    @n.ucRefreshRate = mdln.refresh
    @n.ucInternalModeNumber = mdln.number
  End If

End Function

'============================================================
'  vesa_timing_disable
'============================================================

Function vesa_timing_disable(b As ATOMBIOS, ByVal p As Long Ptr) As Long

  Local m As ATOM_MODE_TIMING Ptr
  Local n As ATOM_DTD_FORMAT Ptr

  If b.vesa_old_format Then
    m = p
    @m.ucInternalModeNumber = 0
  Else
    n = p
    @n.ucInternalModeNumber = 0
  End If

End Function

'============================================================
'  modeline_adjust
'============================================================

Function modeline_adjust(mdln As MODELINE, ByVal r As MONITOR_RANGE Ptr) As Long

  Local xres, yres, dotclock, interlace, doublescan As Long
  Local hfreq, vfreq As Double
  Local vvt_ini As Double
  Local hh, hs, he, ht As Long
  Local line_time, char_time, new_char_time As Double
  Local h_front_porch_min, h_sync_pulse_min, h_back_porch_min As Double
  Local field_active, field_total, field_blank, field_padding As Double

  xres = mdln.width
  yres = mdln.height

  ' Try with progressive
  interlace = 1
  vfreq = @r.h_freq_max / (yres / interlace + Round(@r.h_freq_max * @r.vertical_blank, 0))
  If vfreq < @r.v_freq_min Then
    ' If out of range try with interlace
    interlace = 2
    vfreq = @r.h_freq_max / (yres / interlace + Round(@r.h_freq_max * @r.vertical_blank, 0))
    If vfreq < @r.v_freq_min Then Exit Function
  End If

  vfreq = Min(vfreq, @r.v_freq_max)
  hfreq = vfreq * yres / (interlace * (1 - vfreq * @r.vertical_blank))
  hfreq = Max(hfreq, @r.h_freq_min)

  line_time = 1 / hfreq * 1000000
  h_front_porch_min = @r.h_front_porch * 0.9
  h_sync_pulse_min = @r.h_sync_pulse * 0.9
  h_back_porch_min = @r.h_back_porch * 0.9
  hh = Round(xres / 8, 0)
  hs = 1 : he = 1 : ht = 1
  Do
    char_time = line_time / (hh + hs + he + ht)
    If hs * char_time < h_front_porch_min Or Abs((hs + 1) * char_time - @r.h_front_porch) < Abs( hs * char_time - @r.h_front_porch) Then Incr hs
    If he * char_time < h_sync_pulse_min Or Abs((he + 1) * char_time - @r.h_sync_pulse) < Abs(he * char_time - @r.h_sync_pulse) Then Incr he
    If ht * char_time < h_back_porch_min Or Abs((ht + 1) * char_time - @r.h_back_porch) < Abs(ht * char_time - @r.h_back_porch) Then Incr ht
    new_char_time = line_time / (hh + hs + he + ht)
  Loop Until new_char_time = char_time

  dotclock = hfreq * (hh + hs + he + ht) * 8
  If dotclock < %DOT_CLOCK_MIN Then Exit Function

  field_active = yres / interlace
  field_total = Round(hfreq / vfreq, 0) + IIf(interlace = 2, 0.5, 0)
  field_blank = (Int(hfreq * @r.vertical_blank) + IIf (interlace = 2, 0.5, 0))
  field_padding = field_total - field_blank - field_active
  If field_padding >= field_active Then
    doublescan = 1
    field_padding -= field_active
  End If

  mdln.pclock = dotclock / 10000
  mdln.hactive = xres
  mdln.hbegin  = (hh + hs) * 8
  mdln.hend    = (hh + hs + he) * 8
  mdln.htotal  = (hh + hs + he + ht) * 8
  mdln.vactive = yres
  mdln.vbegin  = yres + (Max(Round(hfreq * @r.v_front_porch, 0), 1) + field_padding / 2)  * interlace
  mdln.vend    = mdln.vbegin + Max(Round(hfreq * @r.v_sync_pulse, 0), 1)  * interlace
  mdln.vtotal  = field_total * interlace
  mdln.interlace  = IIf(interlace = 2, 1, 0)
  mdln.doublescan = doublescan
  mdln.refresh    = Int(vfreq)
  mdln.hsync = IIf(composite_sync, 1, @r.h_sync_polarity)
  mdln.vsync = IIf(composite_sync, 1, @r.v_sync_polarity)

  Function = 1
End Function

'============================================================
'  find_blank_space
'============================================================

Function find_blank_space(ByVal str As String, ByVal start_offset As Long, ByVal end_offset As Long, bytes_needed As Long, match_offset As Long) As Long

  Local str_to_search As String
  If end_offset = 0 Then end_offset = Len(str) - 1
  str_to_search = Mid$(str, start_offset + 1, end_offset - start_offset)
  Replace Chr$(&hff) With Chr$(&h00) In str_to_search

  match_offset = InStr(1, str_to_search, String$(bytes_needed, &h00))
  If IsFalse match_offset Then Exit Function
  Decr match_offset
  match_offset += start_offset
  Function = 1

End Function

'============================================================
'  bios_hook
'============================================================

Function bios_hook(b As ATOMBIOS) As Long

  Local legacy_bios_size As Long
  Local bytes_to_blank, hook_offset_ini, hook_offset, hook_size As Long
  Local standard_modes_offset, vesa_modes_offset As Word
  Local get_BAR_offset, set_value_offset As Long
  Local hook_ptr, hook_target_ptr As String Ptr * (%BIOS_END_OFFSET - %BIOS_HOOK_OFFSET_MIN)
  Local crtc_interlace_control, data_format, interleave_enable, hsync_control, composite_enable, off_0, off_1, off_2, off_3, off_4, off_5 As Long
  Local reprogram_table As BIOS_MODES Ptr

  legacy_bios_size = Peek(Byte, b.bios_ptr + 2) * 512
  hook_size = CodePtr(hook_end) - CodePtr(hook_start)

  ' Set starting point to search for blank space for our hook
  hook_offset_ini = Min(b.file_length, %BIOS_HOOK_OFFSET_MIN)

  ' In case the bios image is smaller than 64Kb, expand and fill it with zeroes
  If b.file_length < %BIOS_MIN_SIZE Then
    bytes_to_blank = %BIOS_MIN_SIZE - b.file_length
    Mid$(b.@bios_ptr, b.file_length + 1) = String$(bytes_to_blank, 0)
    b.file_length = %BIOS_MIN_SIZE
    legacy_bios_size = %BIOS_MIN_SIZE
  End If

  ' Find blank space at the end of legacy bios
  If IsFalse find_blank_space(b.@bios_ptr, hook_offset_ini, %BIOS_END_OFFSET, hook_size, hook_offset) Then

    ' If this is a plain legacy bios and there's not enough space, we can't do anything
    If IsFalse bios_mod_info.gop_ptr Then exit_error("Hook not possible. Not enough blank space below 0xFFFF.")

    ' If this is an hybrid legacy + EFI bios, then there's a chance that we can reallocate the GOP block
    ' for some extra rom space under 64Kb, so let's attempt GOP reallocation
    Local block_start, block_end, block_size As Long
    Local bytes_to_shift, bytes_left As Long
    Local reallocation_success As Long

    block_start = b.gop_ptr - b.bios_ptr
    block_end = block_start + Peek(Byte, b.gop_ptr + 2) * 512

    ' GOP must start below 64Kb for reallocation to be possible
    If block_start < &h10000 Then

      ' Find how many bytes we need to shift the GOP down to make room for our hook
      While bytes_to_shift < hook_size
        Incr bytes_to_shift
        If find_blank_space(b.@bios_ptr, hook_offset_ini, %BIOS_END_OFFSET, hook_size - bytes_to_shift, hook_offset) Then Exit Loop
      Wend

      ' The GOP block needs 512-byte alignment
      Local new_legacy_bios_size As Long
      new_legacy_bios_size = Ceil((legacy_bios_size + bytes_to_shift) / 512) * 512
      bytes_to_shift = new_legacy_bios_size - legacy_bios_size

      ' If we have a microcode block, we need to move it too, to make sure we don't overwrite it
      If b.mcuc_block_ptr Then
        Local mcuc_length As Long
        mcuc_length = Peek(Word, b.mcuc_block_ptr + 10) + 320
        block_end = (b.mcuc_block_ptr - b.bios_ptr) + mcuc_length
      End If

      ' Make sure we don't overflow the 256Kb boundary
      block_size = block_end - block_start
      bytes_left = &h20000 - &h100 - block_end
      If bytes_left >= bytes_to_shift Then
        ' We have enough room, it's safe to move the block
        Local gop_block As String
        gop_block = Mid$(b.@bios_ptr, block_start + 1, block_size)
        Mid$(b.@bios_ptr, block_start + 1 + bytes_to_shift, block_size) = gop_block
        Mid$(b.@bios_ptr, block_start + 1, bytes_to_shift) = String$(bytes_to_shift, Chr$(0))
        ' Update the microcode offset
        If b.mcuc_block_ptr Then
          b.mcuc_block_ptr += bytes_to_shift
          b.@mcuc_offset_ptr = b.mcuc_block_ptr - b.bios_ptr
        End If
        legacy_bios_size = new_legacy_bios_size
        reallocation_success = 1
      End If

    End If
    If IsFalse reallocation_success Then exit_error("Hook not possible. GOP reallocation failed.")
  End If

  ' Extend the bios size to include our hook (default case)
  If hook_offset + hook_size > legacy_bios_size Then legacy_bios_size = Ceil((hook_offset + hook_size) / 512) * 512

  ' Update legacy bios size
  Poke Byte, b.bios_ptr + 2, legacy_bios_size / 512

  hook_ptr = CodePtr(hook_start)
  hook_target_ptr = b.bios_ptr + hook_offset
  Mid$(b.@bios_ptr, hook_offset + 1) = Left$(@hook_ptr, CodePtr(hook_end) - CodePtr(hook_start))

  reprogram_table = hook_target_ptr + CodePtr(standard_modes) - CodePtr(hook_start)
  @reprogram_table = b.reprogram_table

  Poke Word, b.bios_ptr + b.standard_service_call_off + 1, (hook_offset + CodePtr(standard_bios_hook) - CodePtr(hook_start)) - (b.standard_service_call_off + 3)
  Poke Word, b.bios_ptr + b.vesa_service_call_off + 1, (hook_offset + CodePtr(vesa_bios_hook) - CodePtr(hook_start)) - (b.vesa_service_call_off + 3)

  standard_modes_offset = hook_offset + (CodePtr(standard_modes) - CodePtr(hook_start))
  Poke Word, hook_target_ptr + (CodePtr(get_standard_modes_offset) - CodePtr(hook_start))  + 2, standard_modes_offset
  Poke Word, hook_target_ptr + (CodePtr(standard_bios_service) - CodePtr(hook_start)) + 1, b.standard_service_proc - (hook_offset + (CodePtr(standard_bios_service) - CodePtr(hook_start)) + 3)

  vesa_modes_offset = hook_offset + (CodePtr(vesa_modes) - CodePtr(hook_start))
  Poke Word, hook_target_ptr + (CodePtr(get_vesa_modes_offset) - CodePtr(hook_start))  + 2, vesa_modes_offset
  Poke Word, hook_target_ptr + (CodePtr(vesa_bios_service) - CodePtr(hook_start)) + 1, b.vesa_service_proc - (hook_offset + (CodePtr(vesa_bios_service) - CodePtr(hook_start)) + 3)

  Poke Word, hook_target_ptr + (CodePtr(get_pci_bus) - CodePtr(hook_start)) + 3, b.pci_bus_off

  get_BAR_offset = hook_offset + (CodePtr(get_BAR) - CodePtr(hook_start))
  Poke Word, hook_target_ptr + (CodePtr(call_get_BAR4) - CodePtr(hook_start)) + 1, get_BAR_offset - (hook_offset + (CodePtr(call_get_BAR4) - CodePtr(hook_start)) + 3)
  Poke Word, hook_target_ptr + (CodePtr(call_get_BAR1) - CodePtr(hook_start)) + 1, get_BAR_offset - (hook_offset + (CodePtr(call_get_BAR1) - CodePtr(hook_start)) + 3)

  set_value_offset = hook_offset + (CodePtr(set_value) - CodePtr(hook_start))
  Poke Word, hook_target_ptr + (CodePtr(call_set_value1) - CodePtr(hook_start)) + 1, set_value_offset - (hook_offset + (CodePtr(call_set_value1) - CodePtr(hook_start)) + 3)
  Poke Word, hook_target_ptr + (CodePtr(call_set_value2) - CodePtr(hook_start)) + 1, set_value_offset - (hook_offset + (CodePtr(call_set_value2) - CodePtr(hook_start)) + 3)
  Poke Word, hook_target_ptr + (CodePtr(call_set_value3) - CodePtr(hook_start)) + 1, set_value_offset - (hook_offset + (CodePtr(call_set_value3) - CodePtr(hook_start)) + 3)

  get_registers(radeon_family(b.pci_device), crtc_interlace_control, data_format, interleave_enable, hsync_control, composite_enable, off_0, off_1, off_2, off_3, off_4, off_5)
  Poke Word, hook_target_ptr + (CodePtr(crtc_interlace_control_reg) - CodePtr(hook_start)) + 2, crtc_interlace_control
  Poke Word, hook_target_ptr + (CodePtr(data_format_reg) - CodePtr(hook_start)) + 2, data_format
  Poke Word, hook_target_ptr + (CodePtr(interleave_enable_set) - CodePtr(hook_start)) + 2, interleave_enable
  If composite_sync Then Poke Word, hook_target_ptr + (CodePtr(crtc_enable_composite_sync) - CodePtr(hook_start)), &h9090
  Poke Word, hook_target_ptr + (CodePtr(crtc_h_sync_a_cntl_reg) - CodePtr(hook_start)) + 2, hsync_control
  Poke Dword, hook_target_ptr + (CodePtr(crtc_composite_enable_set) - CodePtr(hook_start)) + 2, composite_enable

  Poke Word, hook_target_ptr + (CodePtr(crtc0_enable_interlace) - CodePtr(hook_start)) + 1, Lo(Word, off_0)
  Poke Word, hook_target_ptr + (CodePtr(crtc1_enable_interlace) - CodePtr(hook_start)) + 1, Lo(Word, off_1)
  Poke Word, hook_target_ptr + (CodePtr(crtc2_enable_interlace) - CodePtr(hook_start)) + 1, Lo(Word, off_2)
  Poke Word, hook_target_ptr + (CodePtr(crtc3_enable_interlace) - CodePtr(hook_start)) + 1, Lo(Word, off_3)
  Poke Word, hook_target_ptr + (CodePtr(crtc4_enable_interlace) - CodePtr(hook_start)) + 1, Lo(Word, off_4)
  Poke Word, hook_target_ptr + (CodePtr(crtc5_enable_interlace) - CodePtr(hook_start)) + 1, Lo(Word, off_5)
  Poke Word, hook_target_ptr + (CodePtr(call_crtc0) - CodePtr(hook_start)) + 1, CodePtr(crtc_program_registers) - CodePtr(call_crtc0) - 3
  Poke Word, hook_target_ptr + (CodePtr(call_crtc1) - CodePtr(hook_start)) + 1, CodePtr(crtc_program_registers) - CodePtr(call_crtc1) - 3
  Poke Word, hook_target_ptr + (CodePtr(call_crtc2) - CodePtr(hook_start)) + 1, CodePtr(crtc_program_registers) - CodePtr(call_crtc2) - 3
  Poke Word, hook_target_ptr + (CodePtr(call_crtc3) - CodePtr(hook_start)) + 1, CodePtr(crtc_program_registers) - CodePtr(call_crtc3) - 3
  Poke Word, hook_target_ptr + (CodePtr(call_crtc4) - CodePtr(hook_start)) + 1, CodePtr(crtc_program_registers) - CodePtr(call_crtc4) - 3
  Poke Word, hook_target_ptr + (CodePtr(call_crtc5) - CodePtr(hook_start)) + 1, CodePtr(crtc_program_registers) - CodePtr(call_crtc5) - 3

  Function = hook_target_ptr + CodePtr(checksum_fix) - CodePtr(hook_start)

  Exit Function

  hook_start:

  standard_bios_hook:
                            ! cmp ah, 0
                            ! pushfd
  standard_bios_service:
                            ' call normal video service
                            ! db &he8, 0, 0
                            ! popfd
                            ! jz short standard_bios_service_mod
                            ! retn
  standard_bios_service_mod:
                            ! pushfd
                            ! pushad
                            ! and al, &h7f
                            ! movzx ebx, al
  get_standard_modes_offset:
                            ' add bx, &h0ffff
                            ! db &h81, &hc3, &hff, &hff
                            ! jmp short set_interlace
  vesa_bios_hook:
                            ! cmp al, 2
                            ! pushfd
  vesa_bios_service:
                            ' call vesa video service
                            ! db &he8, 0, 0
                            ! popfd
                            ! jz short vesa_bios_service_mod
                            ! retn
  vesa_bios_service_mod:
                            ! pushfd
                            ! pushad
                            ' and bx, &h3fff
                            ! db &h81, &hE3, &hFF, &h3F
                            ' sub ebx, &h100
                            ! db &h81, &hEB, &h00, &h01
  get_vesa_modes_offset:
                            ' add bx, &h0ffff
                            ! db &h81, &hc3, &hff, &hff
  set_interlace:
                            ! xor cx, cx
                            ' mov cl, cs:[bx]
                            ! db &h2e, &h8a, &h0F
                            ! and cl, 1

  get_pci_bus:
                            ' mov bx, word ptr cs:[pci_bus]
                            ! db &h2E, &h8B, &h1E, 0, 0
                            ! mov dl, &h20 'Base address #4 (BAR4)
  call_get_BAR4:
                            ' call get_BAR
                            ! db &he8, 0, 0
                            ! test al,1
                            ! jnz short found_BAR
                            ! mov dl, &h14 'Base address #1 (BAR1)
  call_get_BAR1:
                            ' call get_BAR
                            ! db &he8, 0, 0
  found_BAR:
                            ! mov dh, ah
                            ! xor dl, dl
                            ! xor bx, bx
  crtc0_enable_interlace:
                            ' mov ebx, crtc0_register_offset
                            ! db &h68, 0, 0
  call_crtc0:
                            ' call crtc_program_registers1
                            ! db &he8, 0, 0
  crtc1_enable_interlace:
                            ' mov ebx, crtc1_register_offset
                            ! db &h68, 0, 0
  call_crtc1:
                            ' call crtc_program_registers0
                            ! db &he8, 0, 0
  crtc2_enable_interlace:
                            ' mov ebx, crtc2_register_offset
                            ! db &h68, 0, 0
  call_crtc2:
                            ' call crtc_program_registers0
                            ! db &he8, 0, 0
  crtc3_enable_interlace:
                            ' mov ebx, crtc3_register_offset
                            ! db &h68, 0, 0
  call_crtc3:
                            ' call crtc_program_registers0
                            ! db &he8, 0, 0
  crtc4_enable_interlace:
                            ' mov ebx, crtc4_register_offset
                            ! db &h68, 0, 0
  call_crtc4:
                            ' call crtc_program_registers0
                            ! db &he8, 0, 0
  crtc5_enable_interlace:
                            ' mov ebx, crtc5_register_offset
                            ! db &h68, 0, 0
  call_crtc5:
                            ' call crtc_program_registers0
                            ! db &he8, 0, 0
  set_interlace_end:
                            ! popad
                            ! popfd
                            ! retn
  get_BAR:
                            ! mov ah, &h80
                            ! mov al, bh
                            ! shl ax, &h10
                            ! mov ah, bl
                            ! mov al, dl
                            ! and al, &hFC
                            ' mov dx, &hCF8
                            ! db &hBA, &hF8, &h0C
                            ! out dx, ax
                            ' mov dx, &hCFC
                            ! db &hBA, &hFC, &h0C
                            ! in ax, dx
                            ! retn
  crtc_program_registers:
                            ! mov ebp, esp
                            ! xor bx, bx
                            ' mov bx, [bp+2]
                            ! db &h8B, &h5E, &h02
                            ! push ecx
  crtc_enable_interlace:
                            ! test cl, 1
                            ! jz short crtc_enable_composite_sync
  crtc_interlace_control_reg:
                            ' mov eax, crtc_interlace_control
                            ! db &h66, &hB8, 0, 0, 0, 0
                            ! add ax, bx
                            ' mov ecx, &h0001
                            ! db &h66, &hB9, 1, 0, 0, 0
  call_set_value1:
                            ' call set_value
                            ! db &he8, 0, 0
  data_format_reg:
                            ' mov eax, data_format
                            ! db &h66, &hB8, 0, 0, 0, 0
                            ! add ax, bx
                            ' mov ecx, &h0000
  interleave_enable_set:
                            ! db &h66, &hB9, 0, 0, 0, 0
  call_set_value2:
                            ' call set_value
                            ! db &he8, 0, 0
  crtc_enable_composite_sync:
                            ! jmp short crtc_program_registers_exit
  crtc_h_sync_a_cntl_reg:
                            ' mov eax, crtc_h_sync_a_cntl
                            ! db &h66, &hB8, 0, 0, 0, 0
                            ! add ax, bx
  crtc_composite_enable_set:
                            ' mov ecx, &h010000
                            ! db &h66, &hB9, 0, 0, 0, 0
  call_set_value3:
                            ' call set_value
                            ! db &he8, 0, 0
  crtc_program_registers_exit:
                            ! pop ecx
                            ! retn 2
  set_value:
                            ! push bx
                            ! push ax
                            ! mov dl, 0
                            ! out dx, ax
                            ! mov dl, 4
                            ! in ax, dx
                            ! or ax, cx
                            ! xchg ax, bx
                            ! pop ax
                            ! mov dl, 0
                            ! out dx, ax
                            ! xchg ax, bx
                            ! mov dl, 4
                            ! out dx, ax
                            ! pop bx
                            ! retn
  checksum_fix:
                            ! db 0
  standard_modes:
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0
  vesa_modes:
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                            ! db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  hook_end:

End Function

'============================================================
'  get_registers
'============================================================

Function get_registers(device As Long, crtc_interlace_control As Long, data_format As Long, interleave_enable As Long, hsync_control As Long, composite_enable As Long,_
                       off_0 As Long, off_1 As Long, off_2 As Long, off_3 As Long, off_4 As Long, off_5 As Long) As Long

  If ASIC_IS_DCE8(device) Then
    crtc_interlace_control = %EVERGREEN_CRTC_INTERLACE_CONTROL
    data_format            = %CIK_LB_DATA_FORMAT
    interleave_enable      = %CIK_INTERLEAVE_EN
    hsync_control          = %EVERGREEN_CRTC_H_SYNC_A_CNTL
    composite_enable       = %EVERGREEN_CRTC_COMP_SYNC_A_EN
    off_0                  = %EVERGREEN_CRTC0_REGISTER_OFFSET
    off_1                  = %EVERGREEN_CRTC1_REGISTER_OFFSET
    off_2                  = %EVERGREEN_CRTC2_REGISTER_OFFSET
    off_3                  = %EVERGREEN_CRTC3_REGISTER_OFFSET
    off_4                  = %EVERGREEN_CRTC4_REGISTER_OFFSET
    off_5                  = %EVERGREEN_CRTC5_REGISTER_OFFSET
  ElseIf ASIC_IS_DCE4(device) Then
    crtc_interlace_control = %EVERGREEN_CRTC_INTERLACE_CONTROL
    data_format            = %EVERGREEN_DATA_FORMAT
    interleave_enable      = %EVERGREEN_INTERLEAVE_EN
    hsync_control          = %EVERGREEN_CRTC_H_SYNC_A_CNTL
    composite_enable       = %EVERGREEN_CRTC_COMP_SYNC_A_EN
    off_0                  = %EVERGREEN_CRTC0_REGISTER_OFFSET
    off_1                  = %EVERGREEN_CRTC1_REGISTER_OFFSET
    off_2                  = %EVERGREEN_CRTC2_REGISTER_OFFSET
    off_3                  = %EVERGREEN_CRTC3_REGISTER_OFFSET
    off_4                  = %EVERGREEN_CRTC4_REGISTER_OFFSET
    off_5                  = %EVERGREEN_CRTC5_REGISTER_OFFSET
  Else
    crtc_interlace_control = %AVIVO_D1CRTC_INTERLACE_CONTROL
    data_format            = %AVIVO_D1MODE_DATA_FORMAT
    interleave_enable      = %AVIVO_D1MODE_INTERLEAVE_EN
    hsync_control          = %AVIVO_D1CRTC_H_SYNC_A_CNTL
    composite_enable       = %AVIVO_D1CRTC_COMP_SYNC_A_EN
    off_0                  = %AVIVO_CRTC0_REGISTER_OFFSET
    off_1                  = %AVIVO_CRTC1_REGISTER_OFFSET
  End If
End Function

'============================================================
'  set_monitor_range
'============================================================

Function set_monitor_range(r As MONITOR_RANGE, args As String) As Long

  r.h_freq_min       = Val(Parse$(args, Any ",-", 1))
  r.h_freq_max       = Val(Parse$(args, Any ",-", 2))
  r.v_freq_min       = Val(Parse$(args, Any ",-", 3))
  r.v_freq_max       = Val(Parse$(args, Any ",-", 4))
  r.h_front_porch    = Val(Parse$(args, Any ",-", 5))
  r.h_sync_pulse     = Val(Parse$(args, Any ",-", 6))
  r.h_back_porch     = Val(Parse$(args, Any ",-", 7))
  r.v_front_porch    = Val(Parse$(args, Any ",-", 8)) / 1000
  r.v_sync_pulse     = Val(Parse$(args, Any ",-", 9)) / 1000
  r.v_back_porch     = Val(Parse$(args, Any ",-", 10)) / 1000
  r.h_sync_polarity  = Val(Parse$(args, Any ",-", 11))
  r.v_sync_polarity  = Val(Parse$(args, Any ",-", 12))
  r.vertical_blank   = r.v_front_porch + r.v_sync_pulse + r.v_back_porch

  Function = VarPtr(r)
End Function

'============================================================
'  match_counter
'============================================================

Function match_counter(start_value As Long, match_value As Long, max_value As Long, mask As Long) As Long

  Local i, end_value As Long
  end_value = start_value

  For i = 1 To mask
    Incr end_value
    If end_value = max_value Then end_value = 0
    If (end_value And mask) = (match_value And mask) Then Exit For
  Next

  Function = start_value + i
End Function

'============================================================
'  set_bit_in_byte
'============================================================

Function set_bit_in_byte(value As Byte, position As Long, bool_val As Long) As Long

  Local mask As Long
  mask = 1
  Shift Left mask, position
  Shift Left bool_val, position
  mask = Not mask
  value = value And mask

  Function = value Or bool_val
End Function

'============================================================
'  compute_checksum
'============================================================

Function compute_checksum(b As ATOMBIOS) As Word

  Local i, bytes As Long
  Local w As Word

  bytes = Peek(Byte, b.bios_ptr + 2) * 512

  For i = 0 To bytes - 1
     w = w + Peek(Byte, b.bios_ptr + i)
  Next i

  Function = w
End Function

'============================================================
'  fix_checksum
'============================================================

Function fix_checksum(b As ATOMBIOS, checksum_fix_ptr As Long) As Long
  Local i, bytes_to_balance, last_byte_to_balance As Long
  Local checksum_diff As Word

  checksum_diff =  b.checksum - compute_checksum(b)
  bytes_to_balance = Int(checksum_diff / &hfe)

  For i = 1 To bytes_to_balance
    Poke Byte, checksum_fix_ptr + i, Peek(checksum_fix_ptr + i) Xor &hfe
  Next

  Poke Byte, checksum_fix_ptr, b.checksum - compute_checksum(b)
  b.checksum = compute_checksum(b)

End Function


'============================================================
'  title0
'============================================================

Function title0(title As String) As String
  Function = String$(80, 61) + $CrLf + title + $CrLf + String$(80, 61)
End Function

'============================================================
'  title1
'============================================================

Function title1(title As String) As String
  Function = $Spc + String$(64, 95) + $CrLf + Space$(7) + title + $CrLf
End Function
