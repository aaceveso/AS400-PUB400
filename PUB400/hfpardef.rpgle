**Free
ctl-opt dftactgrp(*no) actgrp(*new) option(*nodebugio) datedit(*ymd);

// File Declarations
// HPPARDEF01 es el lógico por clave FHHTAB
dcl-f HFPARDEF01 usage(*update:*output) keyed;
dcl-f HFSCPAR    workstn indds(indicators);

// Estructura de Indicadores vinculada a la pantalla
dcl-ds indicators len(99);
  exitKey      ind pos(3);   // CF03
  updateKey    ind pos(11);  // CF11
  pageUp       ind pos(25);  // PAGEUP
  pageDown     ind pos(26);  // PAGEDOWN
  errTab       ind pos(31);  // Error Table ID
  errDes       ind pos(32);  // Error Description
  errKde       ind pos(33);  // Error Key Def
  errDde       ind pos(34);  // Error Data Def
end-ds;

dcl-s recordExists ind;
dcl-s tempTab char(3) inz(''); // Temp variable to detect change of FHHTAB

// --- Bucle Principal del Programa ---
dou exitKey;

  exfmt HFNEW;

  // Screen validation
  screenValidationProc();

  // 3. Buscar el registro en el archivo
  if tempTab <> SC1TAB; // Si la tabla no ha cambiado, no es
    chain SC1TAB HFPARDEF01;
    recordExists = %found(HFPARDEF01);
    if recordExists;
      // Si el registro existe, cargar datos en la pantalla
      SC1DES = FHHDESC;
      SC1KDE = FHHKDEF;
      SC1DDE = FHHDDEF;
      tempTab = FHHTAB;
    else;
      // Si no existe, limpiar campos de detalle
      SC1DES = *blanks;
      SC1KDE = *blanks;
      SC1DDE = *blanks;
      tempTab = SC1TAB; // Actualizar la variable temporal c
    endif;
    tempTab = SC1TAB;
  endif;

  //Screen options
  select;
    when exitKey; // Si se presiona CF03, salir del programa
      leave;
    when updateKey; // Si se presiona CF23, actualizar o cre
      updateKeyProc();
    when pageUp; // Si se presiona Page Up
      pageUpProc();
    when pageDown; // Si se presiona Page Down
      pageDownProc();
    other;
  endsl;
enddo;

// Finalizar programa
*inlr = *on;
return;

// 4. Procedimientos (Funciones y Rutinas)
dcl-proc screenValidationProc;
  SC1MSG = *blanks; // Limpiar mensaje de error
  errTab = *off;
  errDes = *off;
  errKde = *off;
  errDde = *off;
  If not (PageUp or PageDown or UpdateKey or exitKey);
    // Table field
    if SC1TAB = *blanks;
      errTab = *on; // Indicar que el error está en la tabla
      SC1MSG = alignTextRight('Table can not be blank');
    endif;
  endif;
end-proc;

dcl-proc updateKeyProc;
  // UpdateKey <F23>
    if recordExists; // Si el registro se actualiza
      FHHDESC = SC1DES;
      FHHKDEF = SC1KDE;
      FHHDDEF = SC1DDE;
      update FHHREG; // Si existe, actualiza el registro
    else; // Si el registro no existe, lo crea
      FHHTAB = SC1TAB;
      FHHDESC = SC1DES;
      FHHKDEF = SC1KDE;
      FHHDDEF = SC1DDE;
      write FHHREG;  // Si no existe, lo crea
    endif;
    SC1MSG = alignTextRight('Table updated successfully');
    updateKey = *off; // Limpiar indicador de actualización
end-proc;

dcl-proc pageUpProc;
    setll SC1TAB HFPARDEF01; // Posicionar en el registro ac
    readp HFPARDEF01;
    if not %eof(HFPARDEF01);
      SC1TAB = FHHTAB;
      SC1DES = FHHDESC;
      SC1KDE = FHHKDEF;
      SC1DDE = FHHDDEF;
    else;
      setgt *hival HFPARDEF01; // Volver a posicionar en el
      readp HFPARDEF01; // Intentar leer el registro anterio
      SC1TAB = FHHTAB;
      SC1DES = FHHDESC;
      SC1KDE = FHHKDEF;
      SC1DDE = FHHDDEF;
      SC1MSG = alignTextRight('Last Record');
    endif;
    tempTab = SC1TAB;
    pageUp = *off; // Limpiar indicador de Page Up
end-proc;

dcl-proc pageDownProc;
  setgt SC1TAB HFPARDEF01; // Posicionar en el registro actu
  read HFPARDEF01;
  if not %eof(HFPARDEF01);
    SC1TAB = FHHTAB;
    SC1DES = FHHDESC;
    SC1KDE = FHHKDEF;
    SC1DDE = FHHDDEF;
  else;
    setll *loval HFPARDEF01; // Volver a posicionar en el pr
    read HFPARDEF01; // Intentar leer el siguiente registro
    SC1TAB = FHHTAB;
    SC1DES = FHHDESC;
    SC1KDE = FHHKDEF;
    SC1DDE = FHHDDEF;
    SC1MSG = alignTextRight('First Record'); // Mensaje para
  endif;
  tempTab = SC1TAB;
  pageDown = *off; // Limpiar indicador de Page Down
end-proc;

dcl-proc alignTextRight;
  dcl-pi *n char(50);
    texto char(50) const;
  end-pi;

  dcl-s resultado char(50) inz(*blanks); // Variable para al

  // Lógica de la función
  evalr resultado = %trim(texto);
  return resultado;
end-proc;

