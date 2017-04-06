open(ARGS[1]) do input
	open(ARGS[2], "w") do output
		for ln in eachline(input)
			ln = chomp(ln);
			if contains(ln, "Gender=Masc")
				class = "Masc";
				ln = replace(ln, "|Gender=Masc", "");
			elseif contains(ln, "Gender=Fem")
				class = "Fem";
				ln = replace(ln, "|Gender=Fem", "");
			elseif contains(ln, "Gender=Neut")
				class = "Neut";
				ln = replace(ln, "|Gender=Neut", "");
			else
				continue;
			end
			array = split(ln, '|');
			if contains(ln, "Number=Plur")
				if ismatch(r"s$", array[2])
					class *= "-s";
				elseif ismatch(r"e$", array[2])
					class *= "-e";
				elseif ismatch(r"en$", array[2])
					class *= "-en";
				elseif ismatch(r"n$", array[2])
					class *= "-n";
				elseif ismatch(r"er$", array[2])
					continue;
				else
					class *= "-0";
				end
			elseif contains(ln, "Number=Sing")
				if ismatch(r"ung$", array[2])
					class *= "-en";
				elseif ismatch(r"heit$", array[2])
					class *= "-en";
				elseif ismatch(r"keit$", array[2])
					class *= "-en";
				elseif ismatch(r"schaft$", array[2])
					class *= "-en";
				else
					continue;
				end
			else
				continue;
			end
			ln = join(array, '|');
			ln *= "|Class=" * class;
			write(output, ln * "\n");
		end
	end
end

