open(ARGS[1]) do input
	open(ARGS[2], "w") do output
		for ln in eachline(input)
			ln = chomp(ln);
			if contains(ln, "Number=Plur")
				ln = replace(ln, "|Case=Nom", "");
				ln = replace(ln, "|Case=Gen", "");
				ln = replace(ln, "|Case=Acc", "");
				if contains(ln, "Case=Dat")
					array = split(ln, '|');
					if ismatch(r"s$", array[2])
						array[2] = replace(array[2], r"(.*)s$", s"\1");
						ln = join(array, "|");
						ln = replace(ln, "|Case=Dat", "");
					else
						continue;
					end
				end
			elseif contains(ln, "Number=Sing")
				ln = replace(ln, "|Case=Nom", "");
				ln = replace(ln, "|Case=Dat", "");
				ln = replace(ln, "|Case=Acc", "");
				if contains(ln, "Case=Gen") && (contains(ln, "Gender=Masc") || contains(ln, "Gender=Neut"))
					array = split(ln, '|');
					if ismatch(r"es$", array[2])
						array[2] = replace(array[2], r"(.*)es$", s"\1");
					elseif ismatch(r"s$", array[2])
						array[2] = replace(array[2], r"(.*)s$", s"\1");
					end
					ln = join(array, "|");
				end
				ln = replace(ln, "|Case=Gen", "");
			else
				continue;
			end
			write(output, ln * "\n");
		end
	end
end

