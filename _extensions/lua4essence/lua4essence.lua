-- [[
--  https://pandoc.org/lua-filters.html
-- ]]

    -- macro_subst (elem.text, #edpWorkProduct, 'work product')
    -- nettoyage de l'élément (pour éliminer les trailing characters comme les marque de ponctuation)
    -- string.sub('#edpWorkProduct',1,15-1-15) => string.sub('#edpWorkProduct',1,-1) => #edpWorkProduct
    -- string.sub('#edpWorkProduct.',1,15-1-16) => string.sub('#edpWorkProduct.',1,-2) => #edpWorkProduct
	
	-- FORMAT: 'latex', 'html'
    local function generic_subst(elemtext,tag,fullexpansion)
      local tagprefix = '%'
      local tagpostfix = ''
      local fulltag = string.format("%s%s%s",tagprefix,tag,tagpostfix)

	  -- DEBUG
		if FORMAT:match 'latex' then
			format = 'latex'
			-- table_fp = 'chapters/tables.tex'
		elseif FORMAT:match 'html' then
			format = 'html'
			-- table_fp = 'chapters/tables.html'
		else
			print("Not latex nor html, skipping filter...")
		end	  
	  
	  
      if string.sub(elemtext,1, (((string.len(fulltag))-1)-(string.len(elemtext)))) == fulltag then
        if string.len(elemtext) > string.len(fulltag) then
          return pandoc.RawInline(FORMAT, string.format("%s%s",fullexpansion,string.sub(elemtext,string.len(fulltag)+1,-1)))
        else
          return pandoc.RawInline(FORMAT, fullexpansion)
        end
      else
        return nil
      end
    end

    local function construct_subst(elemtext,tag,expansion)
      -- {black}{Apricot}
      -- {Magenta}{LightGrey}
      -- {RubineRed}{LightGrey}
      -- {OrangeRed}{LightGrey}
      local fullexpansion = string.format("%s%s%s",'{\\fcolorbox{RubineRed}{LightGrey}{',expansion,'}}')
      return generic_subst(elemtext,tag,fullexpansion)
    end

    local function light_subst(elemtext,tag,expansion)
      local fullexpansion = expansion -- string.format("%s",expansion)
      return generic_subst(elemtext,tag,fullexpansion)
    end

	-- excerpt from https://github.com/quarto-ext/fontawesome/blob/main/_extensions/fontawesome/fontawesome.lua
    local function awesome_code(icon)	
		if quarto.doc.is_format("html:js") then
		  -- return "<i class=\"fa-solid fa-folder\" aria-label=\"folder\"" -- OK
		  -- return "<i class=\"fa-solid fa-folder\"" -- OK
		  return "<i class=\"fa-solid fa-" .. icon .. "\"></i>"

		  -- detect pdf / beamer / latex / etc
		elseif quarto.doc.is_format("pdf") then
			return "\\faIcon{" .. icon .. "}"
		else
		  return ''
		end	
	end
		
		
    -- http://mirrors.ibiblio.org/CTAN/fonts/fontawesome5/doc/fontawesome5.pdf : liste des direct command des icones font awesome
    -- faStop, faRegistered, faSquare[regular], ...
    -- n'existe pas : faSquareO, faFileO
    --
    -- IMPORTANT : ajouter \\ en préfixe et {} en postfix

    -- http://www.lua.org/pil/20.html : String library
    -- length #edpWorkProduct = 15 // il faut aussi prendre en charge #edpWorkProduct.

    -- https://www.latex-fr.net/3_composition/texte/paragraphes/encadrer_du_texte ! texte encadré 

    Str = function (elem)
      local toreturn = nil    

      -- https://steeven9.github.io/USI-LaTeX/html/packages_hyperref_babel_xcolor3.html
      -- fcolorbox is in package xcolor

      -- tcolorbox is in package tcolorbox (not included in eisvogel)
      -- mdframed is in package mdframed (not included in eisvogel)

      if (elem.text) then
        local result = construct_subst(elem.text,'edpWorkProduct','\\faFile[regular]{} work product')
        if result then toreturn=result end
        -- OK : result = macro_subst(elem.text,'%edpActivity','\\faSquare[regular]{} activity')
        -- OK : result = macro_subst(elem.text,'#edpActivity','\\fbox{activity}')
        -- OK : result = macro_subst(elem.text,'#edpActivity','{\\setlength{\\fboxrule}{2pt}\\fbox{activity}}')
        -- KO : result = macro_subst(elem.text,'#edpActivity','{\\tcbox[top=0pt,left=0pt,right=0pt,bottom=0pt]{activity}}')
        -- KO : result = macro_subst(elem.text,'#edpActivity','{\\mdframed[roundcorner=10pt]{activity}}')
        -- OK : result = macro_subst(elem.text,'#edpActivity','{\\fcolorbox{black}{gray!30}{activity}}')
        -- source https://texdoc.org/serve/tcolorbox.pdf/0 , page 19 :
        -- KO : result = macro_subst(elem.text,'#edpActivity','\\newtcbox{\\xmybox}{arc=7pt} The \\xmybox{quick} brown.')
        result = construct_subst(elem.text,'edpActivity','\\faSignOut* activity') -- icônes possibles : \\faSignOut, \\faGreaterThan, \\faAngleRight
        if result then toreturn=result end

        -- result = light_subst(elem.text,'edpEssence','Essence ' .. awesome_code('trademark') ) --OK \\faTrademark, \\faRegistered
		result = light_subst(elem.text,'edpEssence','Essence ' .. awesome_code('registered') ) --OK \\faRegistered
        if result then toreturn=result end

        result = light_subst(elem.text,'edpNoIcon','Essence icon-free')
        if result then toreturn=result end

		-- quarto.log.output(awesome_code('folder'))
        result = light_subst(elem.text,'edpFolder',awesome_code('folder'))
		-- quarto.log.output(result)
		
        -- result = light_subst(elem.text,'edpFolder','fa folder')		
        if result then toreturn=result end

		
		

        -- no tag matched => toreturn == nil => return self
        if toreturn then
          return toreturn
        else
          return elem
        end
      else
        return elem
      end
    end

-- https://pandoc.org/lua-filters.html#typewise-traversal
-- Filter sets are applied in the order in which they are returned.
return {
  {
    Str = Str
  }
}
