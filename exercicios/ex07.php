<?php
// Exercício 7: Arrays e Funções (Buscador)

function verificarProdutoBloqueado(string $codigoProduto): bool
{
    $bloqueados = ["A12", "B45", "X99"];
    return in_array($codigoProduto, $bloqueados);
}

$codigo = "B45";

if (verificarProdutoBloqueado($codigo)) {
    echo "O produto $codigo está BLOQUEADO para venda.";
} else {
    echo "O produto $codigo está liberado para venda.";
}
