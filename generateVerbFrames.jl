cacheDir = "cache/";

function explodeSentences(file::AbstractString)::Void
	sentence = "";
	buffer = "";
	if isdir(cacheDir)
		rm(cacheDir; recursive = true);
	end
	mkdir(cacheDir);
	open(file) do f
		for line in eachline(f)
			if startswith(line, "# orig_file_sentence")
			elseif startswith(line, "# sent_id")
				sentence = split(split(line)[end], '/')[1];
			elseif line == "\n"
				open(cacheDir * sentence * ".txt", "w") do output
					write(output, buffer);
				end
				buffer = "";
			else
				buffer = buffer * line;
			end
		end
	end
end

function proccessSentence(file::AbstractString)::Array{Array{AbstractString, 1}, 1}
	table = Array{Array{AbstractString, 1}, 1}();
	open(cacheDir * file) do f
		for line in eachline(f)
			push!(table, split(line, "\t"));
		end
	end
	table
end

function sentence2verbs(input::Array{Array{AbstractString, 1}, 1}; expl::Bool = false, obl::Bool = false)::Array{Array{Array{AbstractString, 1}, 1}, 1}
	output = Array{Array{Array{AbstractString, 1}, 1}, 1}();
	# Extract all verbs
	for i in input
		if i[4] == "VERB"
			push!(output, Array{Array{AbstractString, 1}, 1}());
			push!(output[end], i);
		end
	end
	# for each verb, extract its arguments
	for i in input
		for j in output
			if i[7] == j[1][1]
				if ismatch(r"^(nsubj|csubj|obj|iobj|ccomp|xcomp)($|:)", i[8])
					push!(j, i);
				elseif expl && startswith(i[8], "expl")
					push!(j, i);
				elseif obl && startswith(i[8], "obl")
					push!(j, i);
				end
			end
		end
	end
	# extract argument dependents with "case" or "mark" relation
	for i in input
		if i[8] in ["case", "mark"]
			for j in output
				for k in j
					if i[7] == k[1]
						push!(j, i);
					end
				end
			end
		end
	end
	output
end

function processVerb(verbTable::Array{Array{AbstractString, 1}, 1})::Array{AbstractString, 1}
	output = Array{AbstractString, 1}();
	valenceFrame = Array{AbstractString, 1}();
	push!(output, verbTable[1][3]); # Lemma

	features = split(verbTable[1][6], "|");
	form = "null";
	voice = "null";
	for i in features # VerbForm and Voice
		if startswith(i, "VerbForm")
			form = split(i, "=")[2];
		elseif startswith(i, "Voice")
			voice = split(i, "=")[2];
		end
	end
	push!(output, form);
	push!(output, voice);
	push!(output, ":");

	# separate arguments and their dependants
	argumentTable = Array{Array{AbstractString, 1}, 1}();
	casemarkTable = Array{Array{AbstractString, 1}, 1}();
	for i in verbTable[2:end]
		if i[7] == verbTable[1][1]
			push!(argumentTable, i);
		else
			push!(casemarkTable, i);
		end
	end

	for i in argumentTable
		# Extract argument case
		case = "";
		features = split(i[6], "|")
		for j in features
			if startswith(j, "Case")
				case = "-" * split(j, "=")[2];
				break;
			end
		end

		# extract argument dependants
		casemarks = Array{AbstractString, 1}();
		for j in casemarkTable
			if j[7] == i[1] # TODO: check multiples
				push!(casemarks, j[8] * "-" * j[3])
			end
		end
		casemark = "";
		casemark = join(casemarks, ", ");
		if casemark != ""
			casemark = "(" * casemark * ")"
		end

		push!(valenceFrame, i[8] * case * casemark);
	end
	push!(output, join(valenceFrame, ", "));
	output
end

function countFrames(input::Array{Array{AbstractString, 1}, 1})::Array{Array{AbstractString, 1}, 1}
	output = Array{Array{AbstractString, 1}, 1}();
	for (i, it) in enumerate(input)
		if i > 1 && minimum(it .== input[i - 1][1:5]) == 1
			output[end][end] = string(parse(Int, output[end][end]) + 1);
		else
			push!(output, it);
			push!(output[end], "=");
			push!(output[end], "1");
		end
	end
	output
end

function prettyPrint(input::Array{Array{AbstractString, 1}, 1})::AbstractString
	output = "";
	for i in input
		newline = i[1];
		newline = newline * repeat(" ", max(18 - length(newline), 0));
		newline = newline * i[2];
		newline = newline * repeat(" ", max(24 - length(newline), 0));
		newline = newline * i[3];
		newline = newline * repeat(" ", max(30 - length(newline), 0));
		newline = newline * i[4] * " " * i[5];
		newline = newline * repeat(" ", max(75 - length(newline), 0));
		newline = newline * join(i[6:7], " ");
		output = output * newline * "\n";
	end
	output
end

function generateVerbFrames(file::AbstractString; expl::Bool = false, obl::Bool = false)::AbstractString
	explodeSentences(file);
	frames = Array{Array{AbstractString, 1}, 1}();
	for f in readdir(cacheDir)
		table = proccessSentence(f);
		verbTable = sentence2verbs(table; expl = expl, obl = obl);
		for v in verbTable
			push!(frames, processVerb(v));
		end
	end
	rm(cacheDir; recursive = true)
	sort!(frames, by = x -> (x[1], x[2], x[3], x[5]));
	countedFrames = countFrames(frames);
	sort!(countedFrames, by = x -> (x[1], x[2], x[3], 1f0 / parse(Float32, x[7])));
	prettyPrint(countedFrames)
end

function main()
	expl = false;
	obl = false;
	file = "";
	for i in ARGS
		if i == "--expl"
			expl = true;
		elseif i == "--obl"
			obl = true;
		else
			file = i;
		end
	end

	ofile = join(split(file, ".")[1:end-1], ".");
	if expl && obl
		ofile *= ".expl+obl";
	elseif expl
		ofile *= ".expl";
	elseif obl
		ofile *= ".obl";
	end
	ofile *= ".output.txt";

	if file == "" || !isfile(file)
		exit(-1);
	end
	output = generateVerbFrames(file; expl = expl, obl = obl);
	open(ofile, "w") do f
		write(f, output);
	end
end

main();

