# Zumbi Survival — gerar APK Android

Este projeto está preparado para exportação Android (arm64-v8a) pelo GitHub Actions.

## Importante

O APK ainda não foi compilado. A compilação acontece nos servidores do GitHub depois que o projeto for enviado para um repositório.

## Passos

1. Entre em https://github.com/ e crie uma conta ou entre na sua.
2. Crie um repositório novo chamado `zumbi-survival`. Pode deixar privado.
3. Envie todos os arquivos e pastas deste ZIP para a raiz do repositório (não envie o ZIP fechado). Confirme que `project.godot`, `main.tscn`, `scripts/`, `export_presets.cfg` e `.github/workflows/android-apk.yml` aparecem na raiz/locais indicados.
4. Abra a aba **Actions** do repositório. Se aparecer uma confirmação para permitir workflows, confirme.
5. Selecione **Gerar APK Android** e toque em **Run workflow**. Se o envio dos arquivos já disparou a compilação, abra a execução mais recente.
6. Quando terminar com marca verde, abra a execução e baixe **ZumbiSurvival-APK** na seção **Artifacts**.
7. Extraia o arquivo baixado para encontrar `ZumbiSurvival.apk`.

Se a execução ficar vermelha, abra a execução e copie a mensagem de erro para que possamos corrigir o projeto.
