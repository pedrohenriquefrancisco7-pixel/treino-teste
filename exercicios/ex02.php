<?php
// Exercício 2: Desconto Flexível
// O percentual de desconto é opcional (padrão = 5%)

function calcularValorComDesconto(float $valorCompra, float $percentualDesconto = 5): float
{
    $desconto = $valorCompra * ($percentualDesconto / 100);
    return $valorCompra - $desconto;
}

$compra = 200.00;

// 1ª chamada: só o valor da compra (usa o desconto padrão de 5%)
$valorPadrao = calcularValorComDesconto($compra);

// 2ª chamada: valor da compra + desconto de 15%
$valorPromocao = calcularValorComDesconto($compra, 15);

echo "Valor da compra: R$ " . number_format($compra, 2, ',', '.') . "<br>";
echo "Com desconto padrão (5%): R$ " . number_format($valorPadrao, 2, ',', '.') . "<br>";
echo "Com desconto promocional (15%): R$ " . number_format($valorPromocao, 2, ',', '.');
