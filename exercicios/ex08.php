<?php
// Exercício 8: Sanitização de Dados (Segurança XSS)

function limparDadosFormulario(array $dadosBrutos): array
{
    $dadosLimpos = [];

    foreach ($dadosBrutos as $chave => $valor) {
        $dadosLimpos[$chave] = htmlspecialchars(trim($valor));
    }

    return $dadosLimpos;
}

// Teste com tags HTML invasivas
$formulario = [
    "nome" => "   <b>Pedro</b>   ",
    "bio"  => "<script>alert('hackeado!');</script>",
];

$dados = limparDadosFormulario($formulario);

// As tags aparecem como texto na tela e NÃO são executadas
echo "Nome: " . $dados["nome"] . "<br>";
echo "Bio: " . $dados["bio"];
