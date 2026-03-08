**Free
ctl-opt dftactgrp(*no) actgrp(*new) option(*nodebugio) datedit(*ymd);

// File Declarations
// HPPARDEF01 es el lógico por clave FHHTAB
dcl-f HFPARDEF01 usage(*update:*output) keyed;
dcl-f HFSCPAR    workstn indds(indicators);

// Estructura de Indicadores vinculada a la pantalla
dcl-ds indicators len(99);
  exitKey      ind pos(3);   // CF03
  deleteKey    ind pos(6);   // CF06
  updateKey    ind pos(11);  // CF11
  cancelKey    ind pos(12);  // CF12
  pageUp       ind pos(25);  // PAGEUP
  pageDown     ind pos(26);  // PAGEDOWN
  errGroup     ind pos(31) len(4); // Error data (Pos 31-34)
  errTab       ind pos(31);  // Error Table ID
  errDes       ind pos(32);  // Error Description
  errKde       ind pos(33);  // Error Key Def
  errDde       ind pos(34);  // Error Data Def
end-ds;

dcl-s recordExists ind;
dcl-s tempTab char(3) inz(''); // Temp variable to detect change of FHHTAB

// --- Main Procedure ---
dou exitKey;
  exfmt HFNEW;
  screenValidationProc(); // Screen validation
  lookForRecordProc();  // Look for the record in the file only if the table has changed
  screenFunctions(); // Execute screen functions
enddo;

// Finalizar programa
*inlr = *on;
return;

// 4. Procedimientos (Funciones y Rutinas)

dcl-proc screenValidationProc;
  SC1MSG = *blanks; // Limpiar mensaje de error
  errGroup = *off; // Clear error indicators
  If not (PageUp or PageDown or UpdateKey or exitKey);
    // Table field
    if SC1TAB = *blanks;
      errTab = *on; // Indicar que el error está en la tabla
      SC1MSG = alignTextRight('Table can not be blank');
    endif;
  endif;
end-proc;

dcl-proc lookForRecordProc;
  if tempTab <> SC1TAB; // If the table has not changed, no need to search
    chain SC1TAB HFPARDEF01;
    recordExists = %found(HFPARDEF01);
    if recordExists;
      // If record exists, load data into the screen
      SC1TAB = FHHTAB;
      SC1DES = FHHDESC;
      SC1KDE = FHHKDEF;
      SC1DDE = FHHDDEF;
    else;
      // If record does not exist, clear detail fields
      SC1DES = *blanks;
      SC1KDE = *blanks;
      SC1DDE = *blanks;
    endif;
    tempTab = SC1TAB;
  endif;
end-proc;

dcl-proc screenFunctions;
//Screen options
  select;
    when exitKey; // If pressed CF03, exit the program
      return;
    when deleteKey; // If pressed CF06, delete the record;
      deleteConfirmation();
    when updateKey; // If pressed CF11, update or create;
      updateKeyProc();
    when pageUp; // If pressed Page Up
      pageUpProc();
    when pageDown; // If pressed Page Down
      pageDownProc();
    other;
  endsl;
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
  tempTab = SC1TAB;
end-proc;

dcl-proc deleteConfirmation;
  // Confirm deletion
  deleteKey = *off
  SC1MSG = *blanks;
  dow not deleteKey or cancelKey; // Loop until user confirms deletion or cancels
    exfmt HFDEL; // Display confirmation screen
    select;
      when cancelKey; // If user cancels deletion (CF12)
        SC1MSG = alignTextRight('Deletion cancelled');
        SC1TAB = *blanks;
          SC1DES = *blanks;
          SC1KDE = *blanks;
          SC1DDE = *blanks;
          tempTab = SC1TAB; // Update tempTab to reflect the cleared state
      when deleteKey; // If user confirms deletion (CF06)
        chain(e) SC1TAB HFPARDEF01; // Reposition to the record to be deleted
        if not %found(HFPARDEF01);
          SC1MSG = alignTextRight('Record not found for deletion');
        else;
          delete(e) FHHREG; // Eliminar el registro
          if %error; // Check for errors during deletion
            if %status = 1218;
              SC1MSG = alignTextRight('Error deleting record, record in use');
            else;
              SC1MSG = alignTextRight('Error deleting record');
            endif;
          else;
            SC1MSG = alignTextRight('Record deleted successfully');
          endif;
        endif;
      other;
    endsl;
  enddo;
  deleteKey = *off; // clear delete key after processing
  cancelKey = *off; // clear cancel key after processing
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
    text char(50) const;
  end-pi;
  // Declare variables
  dcl-s result char(50) inz(*blanks); // Variable para al
  // Funtion logic to align text to the right
  evalr result = %trim(text);
  return result;
end-proc;

