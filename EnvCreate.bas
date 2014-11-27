' テンプレート
Const TEMPLATE = "env_template_fr.dicon"

Sub EnvReplace()
    ExcecReplace ("aws")
    ExcecReplace ("rehearsal")
    ExcecReplace ("k2")
    ExcecReplace ("k3")
    ExcecReplace ("commerce")
    
    MsgBox ("D:\tmp に出力しました。")
End Sub

Private Sub ExcecReplace(ByVal env As String)
    Dim FSO As Object, buf As String
    Set FSO = CreateObject("Scripting.FileSystemObject")
    Dim ENV_RANGE As Variant
    
    ' 対象範囲
    ENV_RANGE = Worksheets(2).Range("A10:K100").Value
    
   
    If env = "aws" Then
        col = 5
    ElseIf env = "rehearsal" Then
        col = 8
    ElseIf env = "k2" Then
        col = 9
    ElseIf env = "k3" Then
        col = 10
    ElseIf env = "commerce" Then
        col = 11
    End If
    
    inputFile = ThisWorkbook.Path & "\" & TEMPLATE
    With FSO.GetFile(inputFile).OpenAsTextStream
        buf = .ReadAll
        .Close
    End With


    outputFile = "D:\tmp\env_" & env & ".dicon"
    FSO.CreateTextFile outputFile

    For i = 1 To UBound(ENV_RANGE)
        Name = "${" & ENV_RANGE(i, 2) & "}"
        'MsgBox (Name)
        buf = Replace(buf, Name, Replace(ENV_RANGE(i, col), vbLf, vbCrLf))
    Next i

    With FSO.GetFile(outputFile).OpenAsTextStream(2)
        .Write buf
        .Close
    End With

    Set FSO = Nothing
    
End Sub