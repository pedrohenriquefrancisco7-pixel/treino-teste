<?php
// Exercício 3: Múltiplos Parâmetros e Concatenação
// Login = primeira letra do nome + sobrenome completo, tudo em minúsculo

function gerarLogin(string $nome, string $sobrenome): string
{
    $login = $nome[0] . $sobrenome;
    return strtolower($login);
}

$login = gerarLogin("Marcelo", "Formico");

echo "Login gerado: " . $login; // mformico
