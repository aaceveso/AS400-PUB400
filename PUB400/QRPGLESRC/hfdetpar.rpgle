**Free
ctl-opt dftactgrp(*no) actgrp(*new) option(*nodebugio) datedit(*ymd);

//declaración de recepción de parámetro de entrada
dcl-pi *n;
    tabName char(3) const;
end-pi;

// File Declarations
// HPPARDEF01 es el lógico por clave FHHTAB
dcl-f HFPARDEF01 usage(*input) keyed;
dcl-f HFPARDAT01 usage(*update:*output:*delete) keyed;
dcl-f HFSCDET    workstn sfile(HFDAT:rrn) indds(indicators);

// Estructura de Indicadores vinculada a la pantalla
dcl-ds indicators len(99);
    exitKey      ind     pos(3);              // CF03
    deleteKey    ind     pos(6);              // CF06
    updateKey    ind     pos(11);             // CF11
    cancelKey    ind     pos(12);             // CF12
    sflClr       ind     pos(30);             // Subfile clear indicator
    sflDsp       ind     pos(31);             // Subfile display indicator
    sflDspCtl    ind     pos(32);             // Subfile control indicator
    sflEnd       ind     pos(33);             // Subfile end indicator
end-ds;

dcl-s recordExists ind; // Indicator to check if the table definition record exists
dcl-s rrn int(5); // Relative Record Number for subfile processing

// Main procedure
init(); // Call initialization procedure
dou exitKey;
    If rrn > 0;
        sflDsp = *On; // Show data
        Write HFFTR; // Write footer
    Else;
        sflDsp = *Off; // Hide data
        Write HFFTR; // Write footer
        Write HFNULL; // Write "No records" format (OVERLAY)
    EndIf;
    Exfmt HFHDR; // Display the screen and wait for user input
    screenValidationProc(); // Screen validation
    screenFunctions(); // Execute screen functions
enddo;
*inlr = *on;
return;


dcl-proc init;
    // Indicator & variable initialization
    exitKey = *off;
    deleteKey = *off;
    updateKey = *off;
    cancelKey = *off;
    recordExists = *off;
    exitKey = *off;
    cancelKey = *off;
    deleteKey = *off;
    updateKey = *off;
    SC1MSG = *blanks;

    chain tabName HFPARDEF01;     // Read table definition based on the input parameter
    if %found(HFPARDEF01); // If found, prepare the screen fields
        recordExists = *on;
        // Display Table Name and Description centered in the screen title
        SC1TBN = ('TABLE: (' + %trim(tabName) + ') ' + %trim(FHHDESC));
        SC1TBN = alignTextCenter(SC1TBN);
        SC1KTOP = FHHKTIT;
        SC1DTOP = FHHDTIT;
    else; // If not found, error handling for missing table definition
        recordExists = *off;
        SC1MSG = 'Table: (' + %trim(tabName) + ') not found';
        SC1MSG = alignTextRight(SC1MSG);
        SC1KTOP = '';
        SC1DTOP = '';
    endif;

    // Clean up subfile data area and indicators before writing new data
    sflDsp    = *off;
    sflDspCtl = *off;
    sflClr    = *on;

    WRITE HFHDR; // Write the control record to trigger the subfile clear operation

    // Apagar el indicador de limpieza para poder empezar a escribir
    sflClr = *off; // Off the Clear indicator after writing the control record

    RRN = 0; // Init RRN to 0 before starting to read records

    // Load the table data into the subfile based on the input parameter
    setll (tabName) HFPARDAT01; // Position to the first record for the specific table in HFPARDAT01
    reade (tabName) HFPARDAT01; // Read the first record for the specific table to start the loop
    
    Dow not %EOF(HFPARDAT01); // Loop through records for the specific table)
        rrn += 1; // Add 1 to RRN for each record read
        SC2OPT = *Blanks; // Clear the option field for the subfile record
        SC2KEY = FHDKEY; // Map the key field from the file to the subfile key field
        SC2DAT = FHDDAT; // Map the data field from the file to the subfile data field
        write HFDAT; // Write the subfile record to the display file
        reade (tabName) HFPARDAT01; // Read the next record for the specific table to continue the loop
    enddo;

    If rrn > 0; // Si se encontraron registros, activar el indicador de visualización
        sflDsp = *on; // SFLDSP
        sflEnd = *on;
    else; // Si no se encontraron registros, mostrar mensaje de "No records found"
        SC1MSG = 'No records found for table: (' + %trim(tabName) + ')';
        SC1MSG = alignTextRight(SC1MSG);
    endif;
    sflDspCtl = *On;

end-proc;

dcl-proc screenValidationProc;
    SC1MSG = *blanks; // Limpiar mensaje de error
end-proc;

dcl-proc screenFunctions;
        //Screen options
    select;
        when exitKey; // If pressed CF03, exit the program
            return;
        when cancelKey; // If pressed CF12, cancel the update or delete action;
            exitKey = *on;
            return;
        other;
    endsl;
end-proc;

dcl-proc alignTextCenter;
    dcl-pi *n char(65);
        text char(65) const;
    end-pi;

    dcl-s trimmed   char(65);
    dcl-s textLen   int(10);
    dcl-s startPos  int(10);
    dcl-s result    char(65) inz(*blanks);

    trimmed = %trim(text);
    textLen = %len(trimmed);

    // 1. Si el texto está vacío o es mayor/igual al largo máximo, lo devolvemos tal cual
    if textLen <= 0;
        return *blanks;
    elseif textLen >= 65;
        return %subst(trimmed: 1: 65);
    endif;

    // 2. Calcular la posición inicial para que quede centrado
    // La fórmula es: ((LargoTotal - LargoTexto) / 2) + 1
    startPos = %div((65 - textLen): 2) + 1;

    // 3. Insertar el texto en la variable de resultado llena de blancos
    %subst(result: startPos: textLen) = trimmed;

    return result;
end-proc;

dcl-proc alignTextRight;
    dcl-pi *n char(50);
        text char(50) const;
    end-pi;

    dcl-s result char(50) inz(*blanks);

    // EVALR justifica a la derecha automáticamente
    evalr result = %trim(text);

    return result;
end-proc;