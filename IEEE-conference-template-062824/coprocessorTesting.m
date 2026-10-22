clear all; % borra el workspace

%% Configuracion de entorno global
N_ELEMENTS=1024;  % define el numero de elementos de cada vector
BIT_WIDTH = 10;

% Configurar puerto serial
COM_port = "COM4"; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Para las pruebas dinamicas, se recomienda incluir el codigo en un loop que le permita probar varias iteraciones de operaciones
%Genera vectores A y B de 1024 elementos con numeros positivos 
%(puede adaptarse facilmente si usan negativos y positivos).
A=ceil(rand(N_ELEMENTS,1)*2^BIT_WIDTH);
B=ceil(rand(N_ELEMENTS,1)*2^BIT_WIDTH);
% Calculo de referencia en software (Host) para todas las operaciones
Sum_host = A + B;                       % Suma elemento a elemento de vectores A y B
Avg_host = floor((A + B)/2);            % Promedio entero (truncado) de vectores A y B, igual a (A + B) >> 1 en Vivado
Man_host = sum(abs(A - B));             % Distancia Manhattan entre vectores A y B
Euc_host = floor(sqrt(sum((A - B).^2)));% Distancia Euclidiana truncada entre vectores A y B, igual a CORDIC sqrt en Vivado
Dot_host = sum(A .* B);                 % Producto punto entre vectores A y B

% Guarda vectores A y B (cada uno de una columna de 1024 filas) en un
% archivo de texto. Cada linea del archivo contiene un elemento.
h= fopen('VectorA.txt', 'w');
fprintf(h, '%i\n', A);
fclose(h);

h= fopen('VectorB.txt', 'w');
fprintf(h, '%i\n', B);
fclose(h);


%% A partir de aca se realizan las operaciones por medio de comandos al coprocesador

%write2dev escribe un vector almacenado en un archivo de texto en la BRAM indicada por medio de la UART
write2dev('VectorA.txt', 'BRAMA', COM_port); 
write2dev('VectorB.txt', 'BRAMB', COM_port);
% Ejecucion de todos los comandos de lectura y procesamiento en el coprocesador (Device)
VecA_device = command2dev('readVec', 'BRAMA', COM_port);
VecB_device = command2dev('readVec', 'BRAMB', COM_port);
Sum_device  = command2dev('SumVec', COM_port);
Avg_device  = command2dev('avgVec', COM_port); 
Man_device  = command2dev('manDist', COM_port);
Euc_device  = command2dev('eucDist', COM_port);
Dot_device  = command2dev('dotProd', COM_port);
%% Verificacion de resultados (Host vs Device)
fprintf('\n=== Resumen de Verificacion (Host vs Device) ===\n');
fprintf('readVec BRAMA -> Max Error: %d\n', max(abs(VecA_device - A)));
fprintf('readVec BRAMB -> Max Error: %d\n', max(abs(VecB_device - B)));
fprintf('SumVec        -> Max Error: %d\n', max(abs(Sum_device - Sum_host)));
fprintf('avgVec        -> Max Error: %d\n', max(abs(Avg_device - Avg_host)));
fprintf('manDist       -> Host: %d | Device: %d | Error: %d\n', Man_host, Man_device, abs(Man_device - Man_host));
fprintf('eucDist       -> Host: %d | Device: %d | Error: %d\n', Euc_host, Euc_device, abs(Euc_device - Euc_host));
fprintf('dotProd       -> Host: %d | Device: %d | Error: %d\n', Dot_host, Dot_device, abs(Dot_device - Dot_host));


function write2dev(vector, bloque, puertoCOM)
    if bloque == "A" || bloque == "BRAMA"
        addr = uint8(0);
    elseif bloque == "B" || bloque == "BRAMB"
        addr = uint8(1);
    else
        error("Bloque no válido: %s. Use 'A' o 'B'.", string(bloque));
    end
    vec = readmatrix(vector);
    vec = vec(:);
    vec = uint16(vec);
    byte_lsb = uint8(bitand(vec, 255));
    byte_msb = uint8(bitand(bitshift(vec, -8), 7));
    datos = zeros(1, 2048, 'uint8');
    datos(1:2:end) = byte_lsb;
    datos(2:2:end) = byte_msb;
    payload = [addr, datos];
    s = serialport(puertoCOM, 115200, "Timeout", 5);
    flush(s);
    write(s, payload, "uint8");
    clear s;
end


function resultado = command2dev(comando, varargin)

    switch string(comando)
        case "readVec"
            bloque    = varargin{1};
            puertoCOM = varargin{2};
            bloque = upper(string(bloque));
            if bloque == "A" || bloque == "BRAMA"
                cmd = uint8(2);
            elseif bloque == "B" || bloque == "BRAMB"
                cmd = uint8(3);
            else
                error("error: %s", bloque);
            end
            s = serialport(puertoCOM, 115200, "Timeout", 5);
            flush(s);
            write(s, cmd, "uint8");
            bytes_raw = read(s, 2048, "uint8");
            clear s;
            byte_lsb = double(bytes_raw(1:2:end));
            byte_msb = double(bytes_raw(2:2:end));
            vector = byte_lsb + bitshift(byte_msb, 8);
            resultado = vector(:);
        case {"SumVec", "sumVec"}
            puertoCOM = varargin{1};
            cmd = uint8(4);
            s = serialport(puertoCOM, 115200, "Timeout", 5);
            flush(s);
            write(s, cmd, "uint8");
            bytes_raw = read(s, 2048, "uint8");
            clear s;
            byte_lsb = double(bytes_raw(1:2:end));
            byte_msb = double(bytes_raw(2:2:end));
            vector = byte_lsb + bitshift(byte_msb, 8);
            resultado = vector(:);
        case {"AvgVec", "avgVec"}
            puertoCOM = varargin{1};
            cmd = uint8(5);
            s = serialport(puertoCOM, 115200, "Timeout", 5);
            flush(s);
            write(s, cmd, "uint8");
            bytes_raw = read(s, 2048, "uint8");
            clear s;
            byte_lsb = double(bytes_raw(1:2:end));
            byte_msb = double(bytes_raw(2:2:end));
            vector = byte_lsb + bitshift(byte_msb, 8);
            resultado = vector(:);
        case {"manDist", "ManDist"}
            puertoCOM = varargin{1};
            cmd = uint8(6);
            s = serialport(puertoCOM, 115200, "Timeout", 5);
            flush(s);
            write(s, cmd, "uint8");
            bytes_raw = read(s, 3, "uint8");
            clear s;
            resultado = double(bytes_raw(1)) + bitshift(double(bytes_raw(2)), 8) + bitshift(double(bytes_raw(3)), 16);
        case{"eucDist", "EucDist"}
            puertoCOM = varargin{1};
            cmd = uint8(7);
            s = serialport(puertoCOM, 115200, "Timeout", 5);
            flush(s);
            write(s, cmd, "uint8");
            bytes_raw = read(s, 3, "uint8");
            clear s;
            resultado = double(bytes_raw(1)) + bitshift(double(bytes_raw(2)), 8) + bitshift(double(bytes_raw(3)), 16);
        case{"dotProd", "DotProd"}
            puertoCOM = varargin{1};
            cmd = uint8(8);
            s = serialport(puertoCOM, 115200, "Timeout", 5);
            flush(s);
            write(s, cmd, "uint8");
            bytes_raw = read(s, 4, "uint8");
            clear s;
            resultado = double(bytes_raw(1)) + bitshift(double(bytes_raw(2)), 8) + bitshift(double(bytes_raw(3)), 16) + bitshift(double(bytes_raw(4)), 24);
        otherwise
            error("Comando no implementado: %s", string(comando));
    end
end
