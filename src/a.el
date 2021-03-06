;;; -*- lexical-binding: t -*-
;;; a.el --- 

;; Copyright 2013 bobzhang
;;
;; Author: bobzhang@bobzhangs-iMac.local
;; Version: $Id: a.el,v 0.0 2013/01/06 15:25:43 bobzhang Exp $
;; Keywords: 
;; X-URL: not distributed yet

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; 

;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'a)

;;; Code:

(provide 'a)
(eval-when-compile
  (require 'cl))



;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################

(defvar *string-map*
  #s(hash-table
            size 30 data
            ( 3 4)))
(setq '*string-map*
  (make-hash-table "ExLet" "Let"))


(defun string-map-assoc (key &rest)
  (let ((*string-map* #s(hash-table size 30 data ("hgo" 4))))
    (gethash "hgo" *string-map* )))
(let ((e ))
  
  )

(setq v
      (hash-table/from-list
       "CgNil" "Nil"
       "CgCtr" "TypeEq"
       "CgSem" "Sem"
       "CgInh"  "Inherit"
       "CgMth" "Method"
       "CgVal" "Value"
       "CgVir" "Virtual"

       "CeNil" "Nil"
       "CeStr" "Obj"
       "CeTyc" "CEConstraint"
       "CeAnd" "And"
       "CeEq" "ClassExprEq"

       "CrNil" "Nil"
       "CrSem" "Sem"
       "CrCtr" "TypeEq"
       "CrInh" "Inherit"
       "CrIni" "Initializer"
       "CrMth" "Method"
       "CrVal" "Value"
       "CrVir" "Virtual"
       "CrVvr" "VirtualMethod"
         ))
;; (setq v
;;       (hash-table/from-list
;;        "StNil" "Nil"
;;        "StCls" "Class"
;;        "StClt" "ClassType"
;;        "StSem" "Sem"
;;        "StDir" "Directive"
;;        "StExc" "Exception"
;;        "StExt" "External"
;;        "StInc" "Include"
;;        "StMod" "Module"
;;        "StRecMod" "RecModule"
;;        "StMty" "ModuleType"
;;        "StOpn" "Open"
;;        "StTyp" "Type"
;;        "StVal" "Value"
;;          ))
;; (setq v
;;       (hash-table/from-list
;;        "WcTyS" "TypeSubst"
;;        "WcMoS" "ModuleSubst"
;;        "McNil" "Nil"
;;        "McOr" "Or"
;;        "McArr" "Case"
;;        "MeNil" "Nil"
;;        "MeId" "Id"
;;        "MeFun" "Functor"
;;        "MeStr" "Struct"
;;        "MeTyc" "ModuleExprConstraint"
;;        "MePkg" "PackageModule"
;;          ))
;; (setq v
;;       (hash-table/from-list
;;        "WcNil" "Nil"
;;        "WcTyp" "TypeEq"
;;        "WcMod" "ModuleEq"
;;        "WcTys" "TypeSubst"
;;        "WcMos" "ModuleSubst"
;;        "WcAnd" "And"
;;        "BiNil" "Nil"
;;        "BiAnd" "And"
;;        "BiEq" "Bind"
;;        "RbNil" "Nil"
;;        "RbSem" "Sem"
;;        "RbEq" "RecBind"
;;        "MbNil" "Nil"
;;        "MbAnd" "And"
;;        "MbColEq" "ModuleBind"
;;        "MbCol" "ModuleConstraint"
;;          ))


;; (setq v
;;       (hash-table/from-list
;;          "SgNil" "Nil"
;;          "SgCls" "Class"
;;          "SgClt" "ClassType"
;;          "SgSem" "Sem"
;;          "SgDir" "Directive"
;;          "SgExc" "Exception"
;;          "SgExt" "External"
;;          "SgInc" "Include"
;;          "SgMod" "Module"
;;          "SgRecMod" "RecModule"
;;          "SgMty" "ModuleType"
;;          "SgOpn" "Open"
;;          "SgTyp" "Type"
;;          "SgVal" "Value"
;;          ))

;;; a.el ends here
