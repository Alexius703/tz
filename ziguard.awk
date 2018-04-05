# Convert tzdata source into vanguard or rearguard form.

# Contributed by Paul Eggert.  This file is in the public domain.

# This is not a general-purpose converter; it is designed for current tzdata.
#
# When converting to vanguard form, the output can use negative SAVE
# values.
#
# When converting to rearguard form, the output uses only nonnegative
# SAVE values.  The idea is for the output data to simulate the behavior
# of the input data as best it can within the constraints of the
# rearguard format.

BEGIN {
  dst_type["vanguard.zi"] = 1
  dst_type["main.zi"] = 1
  dst_type["rearguard.zi"] = 1

  # The command line should set OUTFILE to the name of the output file.
  if (!dst_type[outfile]) exit 1
  vanguard = outfile == "vanguard.zi"
}

/^Zone/ { zone = $2 }

outfile != "main.zi" {
  in_comment = /^#/
  uncomment = comment_out = 0

  # If this line should differ due to Ireland using negative SAVE values,
  # uncomment the desired version and comment out the undesired one.
  Rule_Eire = /^#?Rule[\t ]+Eire[\t ]/
  Zone_Dublin_post_1968 \
    = (zone == "Europe/Dublin" && /^#?[\t ]+[01]:00[\t ]/ \
       && (!$(in_comment + 4) || 1968 < $(in_comment + 4)))
  if (Rule_Eire || Zone_Dublin_post_1968) {
    if ((Rule_Eire \
	 || (Zone_Dublin_post_1968 && $(in_comment + 3) == "IST/GMT"))	\
	== vanguard) {
      uncomment = in_comment
    } else {
      comment_out = !in_comment
    }
  }

  # If this line should differ due to Namibia using negative SAVE values,
  # uncomment the desired version and comment out the undesired one.
  Rule_Namibia = /^#?Rule[\t ]+Namibia[\t ]/
  Zone_using_Namibia_rule \
    = (zone == "Africa/Windhoek" && /^#?[\t ]+[12]:00[\t ]/ \
       && $(in_comment + 2) == "Namibia")
  if (Rule_Namibia || Zone_using_Namibia_rule) {
    if (in_comment == vanguard) {
      uncomment = in_comment
    } else {
      comment_out = !in_comment
    }
  }

  if (uncomment) {
    sub(/^#/, "")
  }
  if (comment_out) {
    sub(/^/, "#")
  }
}

# If a Link line is followed by a Zone line for the same data, comment
# out the Link line.  This can happen if backzone overrides a Link
# with a Zone.
/^Link/ {
  linkline[$3] = NR
}
/^Zone/ {
  sub(/^Link/, "#Link", line[linkline[$2]])
}

{ line[NR] = $0 }

END {
  for (i = 1; i <= NR; i++)
    print line[i]
}
