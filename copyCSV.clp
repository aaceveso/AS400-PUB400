PGM
             /* 1. Aseguramos la codificación UTF-8 para el archivo Mac */
             CHGATR     OBJ('/home/AACEVES/productos.csv') +
                          ATR(*CCSID) VALUE(1208)

             /* 2. Importamos al archivo físico */
             CPYFRMIMPF FROMSTMF('/home/AACEVES/productos.csv') +
                          TOFILE(AACEVES1/PRODUCTOS) +
                          MBROPT(*REPLACE) +
                          RCDDLM(*ALL) +
                          STRDLM(*NONE) +
                          FLDDLM(';') +
                          DECPNT(*PERIOD) +
                          FROMRCD(2) +
                          RMVBLANK(*BOTH)
                          
             SNDPGMMSG  MSG('Importación completada con éxito')
ENDPGM