#!/usr/bin/env python3
"""
Otimizador de Assets do ConsoleModeVanilla
Reduz o tamanho de texturas TGA mantendo qualidade visual adequada
"""

import os
import shutil
from pathlib import Path
from PIL import Image

# Configurações
MEDIA_PATH = Path(__file__).parent.parent / "Media"
BACKUP_PATH = Path(__file__).parent.parent / "Media_BACKUP"

# Regras de otimização
OPTIMIZE_RULES = {
    "Frames": {
        "resize": (256, 128),  # 512x256 → 256x128
        "quality": 95
    },
    "Crests": {
        "resize": None,  # Já está em 256x256, manter
        "quality": 90
    },
    "Portraits": {
        "resize": None,  # Já está em 256x256, manter
        "quality": 90
    }
}

def backup_media():
    """Cria backup da pasta Media antes de otimizar"""
    if BACKUP_PATH.exists():
        print(f"[OK] Backup ja existe em {BACKUP_PATH}")
        return
    
    print(f"[BACKUP] Criando backup em {BACKUP_PATH}...")
    shutil.copytree(MEDIA_PATH, BACKUP_PATH, dirs_exist_ok=True)
    print("[OK] Backup criado com sucesso")

def get_folder_size(path):
    """Calcula tamanho total de uma pasta"""
    total = 0
    for entry in path.rglob("*"):
        if entry.is_file():
            total += entry.stat().st_size
    return total

def optimize_tga(file_path, target_size=None, quality=95):
    """
    Otimiza arquivo TGA redimensionando e salvando com melhor compressão
    """
    try:
        img = Image.open(file_path)
        original_size = file_path.stat().st_size
        
        # Redimensionar se necessário
        if target_size and img.size != target_size:
            print(f"  [RESIZE] Redimensionando {img.size} -> {target_size}")
            img = img.resize(target_size, Image.Resampling.LANCZOS)
        
        # Salvar com compressão RLE (Run-Length Encoding)
        img.save(file_path, format="TGA", compression="tga_rle")
        
        new_size = file_path.stat().st_size
        reduction = ((original_size - new_size) / original_size) * 100
        
        print(f"  [OK] {file_path.name}: {original_size//1024}KB -> {new_size//1024}KB ({reduction:.1f}% reducao)")
        
        return original_size, new_size
        
    except Exception as e:
        print(f"  [ERRO] Erro ao processar {file_path.name}: {e}")
        return 0, 0

def main():
    print("=" * 60)
    print("OTIMIZADOR DE ASSETS - ConsoleModeVanilla")
    print("=" * 60)
    
    # Criar backup
    backup_media()
    
    # Estatísticas
    total_original = 0
    total_optimized = 0
    
    # Processar cada pasta
    for folder_name, rules in OPTIMIZE_RULES.items():
        folder_path = MEDIA_PATH / folder_name
        
        if not folder_path.exists():
            print(f"[AVISO] Pasta {folder_name} nao encontrada")
            continue
        
        print(f"\n[PASTA] Processando {folder_name}/")
        
        tga_files = list(folder_path.glob("*.tga"))
        
        if not tga_files:
            print(f"  (sem arquivos .tga)")
            continue
        
        for tga_file in tga_files:
            orig, opt = optimize_tga(
                tga_file,
                target_size=rules["resize"],
                quality=rules["quality"]
            )
            total_original += orig
            total_optimized += opt
    
    # Resumo final
    print("\n" + "=" * 60)
    print("RESUMO DA OTIMIZAÇÃO")
    print("=" * 60)
    print(f"Tamanho original:  {total_original / (1024*1024):.2f} MB")
    print(f"Tamanho otimizado: {total_optimized / (1024*1024):.2f} MB")
    print(f"Economia total:    {(total_original - total_optimized) / (1024*1024):.2f} MB ({((total_original - total_optimized) / total_original) * 100:.1f}%)")
    print("\n[OK] Otimizacao concluida!")
    print(f"[BACKUP] Backup dos originais: {BACKUP_PATH}")

if __name__ == "__main__":
    main()
