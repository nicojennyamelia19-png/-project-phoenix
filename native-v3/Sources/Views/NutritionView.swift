import SwiftUI

struct NutritionView: View {
    @AppStorage("phoenix.waterGlasses") private var waterGlasses = 0
    @AppStorage("phoenix.plateProtein") private var protein = "Poulet"
    @AppStorage("phoenix.plateCarb") private var carb = "Riz"
    @AppStorage("phoenix.plateVegetable") private var vegetable = "Légumes verts"

    private let proteins = ["Poulet", "Poisson", "Œufs", "Thon", "Lentilles", "Tofu"]
    private let carbs = ["Riz", "Patate douce", "Pommes de terre", "Pâtes complètes", "Quinoa", "Lentilles"]
    private let vegetables = ["Légumes verts", "Salade composée", "Tomates/concombre", "Courgettes", "Carottes", "Chou"]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PhoenixCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Hydratation", systemImage: "drop.fill")
                            .font(.headline)
                            .foregroundStyle(Color.blue)
                        Text("\(waterGlasses * 250) ml / 3 000 ml")
                            .font(.title.bold())
                        ProgressView(value: min(Double(waterGlasses) / 12, 1))
                            .tint(Color.blue)
                        HStack {
                            Button("+ 250 ml") { waterGlasses = min(waterGlasses + 1, 20) }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.blue)
                            Button("Réinitialiser") { waterGlasses = 0 }
                                .buttonStyle(.bordered)
                        }
                    }
                }

                PhoenixCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Construire mon assiette", systemImage: "circle.grid.cross.fill")
                            .font(.headline)
                        Text("Base simple : ½ légumes, ¼ protéines, ¼ féculents. Ajuste les portions selon ta faim et la séance du jour.")
                            .foregroundStyle(.secondary)

                        Picker("Protéine", selection: $protein) {
                            ForEach(proteins, id: \.self) { Text($0) }
                        }
                        Picker("Féculent", selection: $carb) {
                            ForEach(carbs, id: \.self) { Text($0) }
                        }
                        Picker("Légumes", selection: $vegetable) {
                            ForEach(vegetables, id: \.self) { Text($0) }
                        }

                        VStack(alignment: .leading, spacing: 7) {
                            Label("½ \(vegetable)", systemImage: "leaf.fill")
                                .foregroundStyle(Color.green)
                            Label("¼ \(protein)", systemImage: "bolt.heart.fill")
                                .foregroundStyle(Color.phoenixOrange)
                            Label("¼ \(carb)", systemImage: "circle.hexagongrid.fill")
                                .foregroundStyle(Color.phoenixGold)
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recettes Phoenix")
                        .font(.title2.bold())
                    ForEach(PhoenixRecipe.library) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            PhoenixCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(recipe.name).font(.headline)
                                        Text("\(recipe.category) • \(recipe.minutes) min")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("\(recipe.protein) g")
                                            .font(.headline)
                                            .foregroundStyle(Color.phoenixOrange)
                                        Text("protéines")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Nutrition")
    }
}

private struct RecipeDetailView: View {
    let recipe: PhoenixRecipe

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PhoenixCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Text(recipe.name).font(.largeTitle.bold())
                        Text("\(recipe.minutes) min • environ \(recipe.calories) kcal • \(recipe.protein) g de protéines")
                            .foregroundStyle(.secondary)
                    }
                }
                PhoenixCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("Ingrédients").font(.title2.bold())
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            Label(ingredient, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                PhoenixCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Préparation").font(.title2.bold())
                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .frame(width: 30, height: 30)
                                    .background(Color.phoenixOrange, in: Circle())
                                Text(instruction)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
    }
}
