-- 1. CRIAR BANCO
DROP DATABASE IF EXISTS Rosario;
GO
CREATE DATABASE Rosario;
GO
USE Rosario;
GO

-- 2. TABELAS

CREATE TABLE ALUNOS (
    MATRICULA INT IDENTITY(1,1) PRIMARY KEY,
    NOME VARCHAR(50) NOT NULL
);

CREATE TABLE CURSOS (
    CURSO CHAR(3) PRIMARY KEY,
    NOME VARCHAR(50) NOT NULL
);

CREATE TABLE PROFESSOR (
    PROFESSOR INT IDENTITY(1,1) PRIMARY KEY,
    NOME VARCHAR(50) NOT NULL
);

CREATE TABLE MATERIAS (
    SIGLA CHAR(3) NOT NULL,
    NOME VARCHAR(50) NOT NULL,
    CARGAHORARIA INT NOT NULL,
    CURSO CHAR(3) NOT NULL,
    PROFESSOR INT NOT NULL,
    PRIMARY KEY (SIGLA, CURSO, PROFESSOR),
    FOREIGN KEY (CURSO) REFERENCES CURSOS(CURSO),
    FOREIGN KEY (PROFESSOR) REFERENCES PROFESSOR(PROFESSOR)
);

CREATE TABLE MATRICULA (
    MATRICULA INT,
    CURSO CHAR(3),
    MATERIA CHAR(3),
    PROFESSOR INT,
    PERLETIVO INT,
    N1 FLOAT, N2 FLOAT, N3 FLOAT, N4 FLOAT,
    TOTALPONTOS FLOAT,
    MEDIA FLOAT,
    F1 INT, F2 INT, F3 INT, F4 INT,
    TOTALFALTAS INT,
    PERCFREQ FLOAT,
    RESULTADO VARCHAR(20),
    MEDIAFINAL FLOAT,
    NOTAEXAME FLOAT,
    PRIMARY KEY (MATRICULA, CURSO, MATERIA, PROFESSOR, PERLETIVO),
    FOREIGN KEY (MATRICULA) REFERENCES ALUNOS(MATRICULA),
    FOREIGN KEY (CURSO) REFERENCES CURSOS(CURSO),
    FOREIGN KEY (PROFESSOR) REFERENCES PROFESSOR(PROFESSOR)
);
GO

-- 3. DADOS INICIAIS

INSERT INTO ALUNOS (NOME) VALUES 
('Ana Clara'), ('Bruno Silva'), ('Carlos Eduardo'), 
('Daniela Nunes'), ('Eduarda Lima');

INSERT INTO CURSOS (CURSO, NOME) VALUES 
('ENG', 'Engenharia de Software');

INSERT INTO PROFESSOR (NOME) VALUES 
('Dr. Roberto'), ('Profa. Julia'), 
('Dr. Henrique'), ('Profa. Mariana'), 
('Prof. João');

INSERT INTO MATERIAS (SIGLA, NOME, CARGAHORARIA, CURSO, PROFESSOR) VALUES
('ES1', 'Engenharia de Software I', 72, 'ENG', 1),
('PGR', 'Programação', 72, 'ENG', 2),
('BD1', 'Banco de Dados I', 72, 'ENG', 3),
('REQ', 'Requisitos de Software', 72, 'ENG', 4),
('UML', 'Modelagem UML', 72, 'ENG', 5);
GO

-- 4. PROCEDURE DE MATRÍCULA

CREATE OR ALTER PROCEDURE procMATRICULAALUNO (
    @pNOME VARCHAR(50),
    @pCURSO CHAR(3)
)
AS
BEGIN
    DECLARE @vMATRICULA INT;

    INSERT INTO ALUNOS (NOME) VALUES (@pNOME);
    SET @vMATRICULA = SCOPE_IDENTITY();

    INSERT INTO MATRICULA (MATRICULA, CURSO, MATERIA, PROFESSOR, PERLETIVO)
    SELECT 
        @vMATRICULA,
        M.CURSO,
        M.SIGLA,
        M.PROFESSOR,
        2025
    FROM MATERIAS M
    WHERE M.CURSO = @pCURSO;
END;
GO

-- 5. PROCEDURE DE LANÇAR NOTAS

CREATE OR ALTER PROCEDURE sp_CadastraNotas (
    @MATRICULA INT,
    @CURSO CHAR(3),
    @MATERIA CHAR(3),
    @PERLETIVO INT,
    @NOTA FLOAT,
    @FALTA INT,
    @BIMESTRE INT
)
AS
BEGIN
    DECLARE @MEDIA FLOAT;
    DECLARE @CARGA INT;
    DECLARE @FREQ FLOAT;
    DECLARE @TOTALFALTAS INT;
    DECLARE @RESULTADO VARCHAR(20);

    IF @BIMESTRE = 1
    BEGIN
        UPDATE MATRICULA SET
            N1 = @NOTA,
            F1 = @FALTA,
            TOTALPONTOS = @NOTA,
            TOTALFALTAS = @FALTA,
            MEDIA = @NOTA
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;
    END
    ELSE IF @BIMESTRE = 2
    BEGIN
        UPDATE MATRICULA SET
            N2 = @NOTA,
            F2 = @FALTA,
            TOTALPONTOS = ISNULL(N1, 0) + @NOTA,
            TOTALFALTAS = ISNULL(F1, 0) + @FALTA,
            MEDIA = (ISNULL(N1, 0) + @NOTA) / 2
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;
    END
    ELSE IF @BIMESTRE = 3
    BEGIN
        UPDATE MATRICULA SET
            N3 = @NOTA,
            F3 = @FALTA,
            TOTALPONTOS = ISNULL(N1, 0) + ISNULL(N2, 0) + @NOTA,
            TOTALFALTAS = ISNULL(F1, 0) + ISNULL(F2, 0) + @FALTA,
            MEDIA = (ISNULL(N1, 0) + ISNULL(N2, 0) + @NOTA) / 3
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;
    END
    ELSE IF @BIMESTRE = 4
    BEGIN
        SELECT @CARGA = CARGAHORARIA FROM MATERIAS WHERE SIGLA = @MATERIA AND CURSO = @CURSO;

        UPDATE MATRICULA SET
            N4 = @NOTA,
            F4 = @FALTA,
            TOTALPONTOS = ISNULL(N1,0) + ISNULL(N2,0) + ISNULL(N3,0) + @NOTA,
            TOTALFALTAS = ISNULL(F1,0) + ISNULL(F2,0) + ISNULL(F3,0) + @FALTA,
            MEDIA = (ISNULL(N1,0) + ISNULL(N2,0) + ISNULL(N3,0) + @NOTA) / 4
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;

        SELECT @TOTALFALTAS = TOTALFALTAS, @MEDIA = MEDIA 
        FROM MATRICULA 
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;

        SET @FREQ = 100 * (1 - (@TOTALFALTAS * 1.0 / @CARGA));

        IF @FREQ < 75
            SET @RESULTADO = 'REPROVADO POR FALTA';
        ELSE IF @MEDIA >= 7
            SET @RESULTADO = 'APROVADO';
        ELSE IF @MEDIA < 4
            SET @RESULTADO = 'REPROVADO';
        ELSE
            SET @RESULTADO = 'EXAME';

        UPDATE MATRICULA SET
            RESULTADO = @RESULTADO,
            PERCFREQ = @FREQ
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;
    END
END;
GO

EXEC procMATRICULAALUNO 'Ana Clara','ENG'


          


