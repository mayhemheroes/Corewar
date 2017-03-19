/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_print_strings.c                                 :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: ewallner <ewallner@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2017/03/17 14:16:11 by ewallner          #+#    #+#             */
/*   Updated: 2017/03/18 15:04:21 by nsabbah          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "vm.h"

void ft_print_strings(t_env *e, int ac)
{
  int i;
  int k;
  char *str;
  int hex;

  ft_printf("\n %d \n", BUFF_SIZE);
  i = 0;
  while(++i < ac)
  {
    ft_printf("\n\nFile: %i, Len: %i ----->\n", i, e->player[i].len);
    str = e->player[i].string;
    k = -1;

    while(++k < e->player[i].len)
	{
		hex = 0xFF & (*str);
		(hex <= 0xF) ? ft_printf("0%x", hex) : ft_printf("%x", hex);
		ft_putchar(' ');
		if ((k + 1) % 16 == 0)
			ft_printf("\n");
		str++;
	}
  }
}