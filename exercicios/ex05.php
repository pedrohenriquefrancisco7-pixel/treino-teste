<?php
// Exercício 5: Early Return (Retorno Antecipado)
// Sem usar else: cada regra impeditiva retorna imediatamente

function calcularFrete(float $distancia, float $peso): string|float
{
    if ($distancia > 1000) {
        return "Entrega não suportada";
    }

    if ($peso > 50) {
        return "Carga muito pesada";
    }

    return $distancia * 0.5;
}

echo "1500 km e 10 kg: " . calcularFrete(1500, 10) . "<br>";
echo "300 km e 80 kg: " . calcularFrete(300, 80) . "<br>";
echo "300 km e 20 kg: R$ " . number_format(calcularFrete(300, 20), 2, ',', '.');
