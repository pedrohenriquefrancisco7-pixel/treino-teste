<?php
// Exercício 6: Correção de Bug (Problema de Escopo)

/*
 * CÓDIGO ORIGINAL (com bug):
 *
 *   $imposto = 0.15;
 *
 *   function calcularTributo($valor) {
 *       return $valor * $imposto;
 *   }
 *
 *   echo "Tributo: " . calcularTributo(100);
 *
 * POR QUE NÃO FUNCIONA?
 * Por causa do escopo das variáveis ("Regra de Las Vegas": o que acontece
 * dentro da função, fica dentro da função). A variável $imposto foi criada
 * FORA da função, então ela NÃO EXISTE dentro de calcularTributo().
 * Lá dentro o PHP considera $imposto indefinida e o cálculo dá errado.
 *
 * CORREÇÃO:
 * Passar o imposto como parâmetro da função, para que o valor
 * atravesse a fronteira do escopo do jeito certo.
 */

$imposto = 0.15;

function calcularTributo(float $valor, float $imposto): float
{
    return $valor * $imposto;
}

echo "Tributo: " . calcularTributo(100, $imposto); // Tributo: 15
