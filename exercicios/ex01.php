<?php
// Exercício 1: Conversor de Moedas
// Taxa de câmbio fixa: 1 Dólar = R$ 5,00

function converterParaDolar(float $valorReais): float
{
    $taxaCambio = 5.00;
    return $valorReais / $taxaCambio;
}

// Fora da função: cria a variável, chama a função e imprime
$valor = 150.00;
$valorDolar = converterParaDolar($valor);

echo "R$ " . number_format($valor, 2, ',', '.') . " = US$ " . number_format($valorDolar, 2, '.', ',');
