<?php
// Exercício 4: Validação Booleana com Type Hinting
// A senha é válida se tiver 8 ou mais caracteres

function validarSenha(string $senha): bool
{
    if (strlen($senha) >= 8) {
        return true;
    }
    return false;
}

$senha = "abc12345";

if (validarSenha($senha)) {
    echo "Senha Aprovada";
} else {
    echo "Senha muito curta";
}
