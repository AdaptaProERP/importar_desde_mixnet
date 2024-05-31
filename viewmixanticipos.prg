// Programa   : VIEWMIXANTICIPOS               
// Fecha/Hora : 14/11/2023 23:04:32
// Propósito  : Visualizar Anticipos
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cFile,lDelete)
  LOCAL cFilter

  DEFAULT cFile  :="C:\MIXCLUB\COMP01\mxtrapag.dbf",;
          lDelete:=.f.

  IF !FILE(cFile)
    ? cFile,"NO EXISTE"
    RETURN .T.
  ENDIF

  cFilter=[VENCE>=CTOD("]+DTOC(FchIniMes(oDp:dFecha))+[") .AND. TIPO="ND" ]

  EJECUTAR("DBFVIEWARRAY",cFile,cFilter)

RETURN .T.
// EOF

