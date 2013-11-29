#!/usr/bin/perl
=begin comment
    *** EP 2 ***
    
    Nomes:	
    	Danilo Novais (NUSP 7990759)
    	Ricardo Mikio Morita (NUSP 5412562)
    	
    Matéria:
    	Métodos Formais

    Referências:
    	
=end comment
=cut

use strict;
use warnings;

########################Declaracao de Variaveis Globais########################

my %variaveis;
my @variaveis;
my @predicados;


###############################################################################


########################Declaracao de Funcoes##################################

sub substituiValores2
{
	my $predAtual = shift;
    my @restricoes = split(/,/, shift);
    
    my $pertenceDominio = 1;
		
	#Substitui as variaveis nas clausulas pelos indices das mesmas
	foreach my $variavel (@variaveis)
	{
		$predAtual =~ s/$variavel/$variaveis{$variavel}->[2]/gx;
		
		foreach my $restAtual (@restricoes)
		{
			$restAtual =~ s/$variavel/$variaveis{$variavel}->[2]/gx;
		}
	}
			
	#Prepara as restricoes de dominio para tratamento condicional
	foreach my $restAtual(@restricoes) 
	{
		#Retira os espaços em branco
		$restAtual =~ s/\s//gx;
		
		#Substitui "=" por "==" caso nao seja "!=", "<=" ou ">="
		if ($restAtual !~ m/(!=|<=|>=)/gx)
		{
			$restAtual =~ s/=/==/x;
		}
		
		if (!(eval $restAtual))
		{
			$pertenceDominio = 0;
		}
	}
	
	if ($pertenceDominio)
	{
		print $predAtual . "\n";
	}
}

sub substituiValores
{
	foreach my $predicado (@predicados)
	{
		my $predAtual = $predicado->[0];
		my $restricoes = $predicado->[1];
		
		#my @restricoes = split(/,/, $predicado->[1]);
		
		atualizaVariaveis($predAtual,$restricoes,@variaveis);				
	}
}

sub atualizaVariaveis
{	
	my $predicado = shift;
	my $restricao = shift;
	
	unless (@_ == 0)
	{
		my $atual = shift @_;
		
		for (my $i = $variaveis{$atual}->[0]; $i <= $variaveis{$atual}->[1]; $i++)
		{
			$variaveis{$atual}->[2] = $i;
			atualizaVariaveis($predicado,$restricao,@_);
			if (@_ == 0)
			{
				substituiValores2($predicado,$restricao);
			}
		}
		$variaveis{$atual}->[2] = $variaveis{$atual}->[0];
	}
}

###############################################################################


open (FILEOUT,">SAIDA") || die ("ERRO: Criacao Arquivo");

my $i = 0;

$, = " ";


while (<>) {
	#Declaracao de variaveis e armazenamento destas
	#As variaveis podem estar na mesma linha OU NAO
	if ($_ =~ m/^\s*([A-Z]+)\s*:\s*(\d+)\s*(\d+)\s*\.(.*)/x) {
		#print $1 . " " . $2 . " " . $3 . "\n";
		$variaveis{$1} = [$2,$3,$2];
		
		$_ = $4;
		#print "S4: $_ \n";
		redo if (defined $_);
	}
	
	# Captura as clausulas e, reprocessa a linha caso haja mais argumentos
	# na mesma linha
	elsif ($_ =~ m/^(.+\))\s*\.(.*)/x)
	{
		#print "dominio: " . $1 . "\n";
		$predicados[$i++][0] .= $1;
		
		$_ = $2;
		if (defined $_ && $_ =~ m/^\s*([A-Z]+.+)(\.|\,)/x)
		{
			redo;
		}
		else
		{
		 	$predicados[$i-1][1] = "1";
		}
	}
	
	elsif ($_ =~ m/^(.+\))/x)
	{
		#print "dominio: " . $1 . "\n";
		$predicados[$i][0] .= $1 . " ";
	}
	 
	#Restricao de dominio da clausula que esta em outra linha
	elsif ($_ =~ m/^\s*([A-Z]+.+)(\.|\,)/x)
	{
		#print "restricao: " . $1 . "\n";
		$predicados[$i-1][1] .= $1 . ",";
		
	}

}

# Agora as variaveis estao no hash %variaveis e os predicados estao 
# no array @predicados, sendo que cada celula deste array e composta
# por uma string de clausulas([0]) e uma string de restricoes([1]).

@variaveis = keys %variaveis;
print "Variaveis: " . @variaveis;

print "\n";
#print keys %variaveis;
print "Clausulas: \"" . $predicados[0][0] . "\" , com as restricoes: \"" . $predicados[0][1] . "\"\n\n";
#print $predicados[1][0] . " e aqui as restricoes: " . $predicados[1][1] . "\n";
#print $predicados[2][0] . " e aqui as restricoes: " . $predicados[2][1] . "\n";

#atualizaVariaveis (@variaveis);
substituiValores();
#print "\n". $restricoes[0] . $restricoes[1];


close(FILEOUT);